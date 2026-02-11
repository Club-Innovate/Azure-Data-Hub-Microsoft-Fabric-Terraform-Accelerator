# Policy-as-Code with OPA

Policy-as-Code shifts governance enforcement left in the development lifecycle, enabling automated validation of infrastructure configurations before deployment.

---

## What is Policy-as-Code?

**Policy-as-Code** is the practice of defining, testing, and enforcing governance policies using code rather than manual processes.

### Benefits

- ✅ **Shift Left**: Catch issues before deployment, not after
- ✅ **Automated Enforcement**: Consistent policy application
- ✅ **Fast Feedback**: Developers know immediately if changes violate policies
- ✅ **Version Control**: Policies stored in Git alongside infrastructure code
- ✅ **Auditable**: Track policy changes over time
- ✅ **CI/CD Integration**: Automated gates in deployment pipelines

**Reference**: [Open Policy Agent](https://www.openpolicyagent.org/)

---

## Technology Stack

### Open Policy Agent (OPA)

**OPA** is a general-purpose policy engine that uses **Rego** language for defining policies.

- **Declarative**: Describe what should be true, not how to check it
- **Flexible**: Works with any structured data (JSON, YAML, etc.)
- **Fast**: Optimized for low-latency policy evaluation
- **Portable**: Runs anywhere (CLI, servers, Kubernetes, CI/CD)

**Reference**: [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)

### Conftest

**Conftest** is a CLI tool that uses OPA to test structured configuration files.

- Validates Terraform plans (JSON format)
- Works with Kubernetes manifests, Dockerfiles, and more
- Integrates easily with CI/CD pipelines
- Simple setup: `conftest test <file>`

**Reference**: [Conftest Documentation](https://www.conftest.dev/)

### Rego Language

**Rego** is OPA's native policy language:

```rego
package main

# Deny public blob access on storage accounts
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.allow_blob_public_access == true
    
    msg := sprintf(
        "Storage account '%s' must disable public blob access",
        [resource.name]
    )
}
```

**Reference**: [Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)

---

## Policy Files in This Accelerator

Located in `policy/` directory:

| Policy File | Purpose | Example Rules |
|-------------|---------|---------------|
| `naming.rego` | Resource naming conventions | Prefix validation, naming patterns |
| `tags.rego` | Required tags validation | Ensure cost_center, owner, project tags |
| `storage.rego` | Storage security | Encryption, TLS, public access |
| `regions.rego` | Allowed Azure regions | Restrict deployments to specific regions |
| `logging.rego` | Diagnostic settings | Ensure logging enabled for all resources |
| `rbac.rego` | Role assignment validation | Prevent overly permissive roles |
| `fabric.rego` | Fabric-specific policies | Capacity SKU validation, admin assignment |
| `diagnostics.rego` | Diagnostic configuration | Log Analytics integration |

---

## Example Policies

### 1. Storage Security Policy

```rego
package main

# Deny public blob access
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.allow_blob_public_access == true
    
    msg := sprintf(
        "Storage account '%s' must disable public blob access for compliance",
        [resource.name]
    )
}

# Enforce TLS 1.2+
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.min_tls_version != "TLS1_2"
    
    msg := sprintf(
        "Storage account '%s' must enforce TLS 1.2 or higher",
        [resource.name]
    )
}

# Require HTTPS only
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.enable_https_traffic_only != true
    
    msg := sprintf(
        "Storage account '%s' must enable HTTPS traffic only",
        [resource.name]
    )
}
```

### 2. Tagging Policy

```rego
package main

# Required tags
required_tags := ["owner", "cost_center", "project"]

# Deny resources without required tags
deny[msg] {
    resource := input.resource_changes[_]
    not resource.change.after.tags
    
    msg := sprintf(
        "Resource '%s' of type '%s' is missing tags",
        [resource.name, resource.type]
    )
}

deny[msg] {
    resource := input.resource_changes[_]
    tags := resource.change.after.tags
    missing := {tag | tag := required_tags[_]; not tags[tag]}
    count(missing) > 0
    
    msg := sprintf(
        "Resource '%s' is missing required tags: %v",
        [resource.name, missing]
    )
}
```

### 3. Region Restriction Policy

```rego
package main

# Allowed Azure regions
allowed_regions := ["eastus", "westus", "westus2", "centralus"]

# Deny deployment to disallowed regions
deny[msg] {
    resource := input.resource_changes[_]
    location := resource.change.after.location
    not location in allowed_regions
    
    msg := sprintf(
        "Resource '%s' location '%s' is not allowed. Permitted regions: %v",
        [resource.name, location, allowed_regions]
    )
}
```

### 4. Naming Convention Policy

```rego
package main

# Naming patterns
naming_patterns := {
    "azurerm_resource_group": "^[a-z0-9-]+-(dev|qa|prod)-rg$",
    "azurerm_storage_account": "^[a-z0-9]{3,24}$",
    "azurerm_data_factory": "^[a-z0-9-]+-(dev|qa|prod)-adf$",
}

# Warn if naming convention not followed
warn[msg] {
    resource := input.resource_changes[_]
    pattern := naming_patterns[resource.type]
    name := resource.change.after.name
    not re_match(pattern, name)
    
    msg := sprintf(
        "Resource '%s' of type '%s' does not follow naming pattern: %s",
        [name, resource.type, pattern]
    )
}
```

---

## Running Policies Locally

### 1. Install Conftest

```bash
# macOS (Homebrew)
brew install conftest

# Windows (Chocolatey)
choco install conftest

# Linux (Binary download)
wget https://github.com/open-policy-agent/conftest/releases/download/v0.45.0/conftest_0.45.0_Linux_x86_64.tar.gz
tar xzf conftest_0.45.0_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin/
```

### 2. Generate Terraform Plan JSON

```powershell
# For infra root
terraform -chdir=infra plan -out=tfplan -var-file=../terraform.tfvars
terraform -chdir=infra show -json tfplan > infra/plan.json

# For fabric root
terraform -chdir=fabric plan -out=tfplan -var-file=../terraform.tfvars
terraform -chdir=fabric show -json tfplan > fabric/plan.json
```

**Why JSON?**
- Terraform's JSON format is structured and machine-readable
- OPA can parse and query JSON natively
- Consistent format across all Terraform versions

**Reference**: [Terraform JSON Output](https://developer.hashicorp.com/terraform/internals/json-format)

### 3. Run Conftest

```powershell
# Test infra plan (table output)
conftest test --policy policy infra/plan.json -o table

# Test fabric plan (JSON output for CI/CD)
conftest test --policy policy fabric/plan.json -o json

# Test all plans
conftest test --policy policy infra/plan.json fabric/plan.json
```

### 4. Review Results

**Table Output** (human-readable):
```
+---------+------------------+----------------------------------------------------+
| RESULT  | POLICY           | MESSAGE                                            |
+---------+------------------+----------------------------------------------------+
| FAILURE | storage.rego     | Storage account 'acmedevsa' must disable public    |
|         |                  | blob access for compliance                         |
| WARNING | naming.rego      | Resource 'test-rg' does not follow naming pattern  |
| SUCCESS | tags.rego        | All resources have required tags                   |
+---------+------------------+----------------------------------------------------+

3 tests, 1 passed, 1 warning, 1 failure, 0 exceptions
```

**JSON Output** (for CI/CD parsing):
```json
[
  {
    "filename": "infra/plan.json",
    "warnings": [
      {
        "msg": "Resource 'test-rg' does not follow naming pattern"
      }
    ],
    "failures": [
      {
        "msg": "Storage account 'acmedevsa' must disable public blob access"
      }
    ]
  }
]
```

---

## CI/CD Integration

### Azure DevOps Pipeline

The accelerator includes policy validation in `ci-cd/azure-pipelines.yml`:

```yaml
# Generate plan JSON
- task: PowerShell@2
  displayName: 'Terraform Plan (Infrastructure)'
  inputs:
    script: |
      terraform -chdir=infra plan -out=tfplan -var-file=../terraform.tfvars
      terraform -chdir=infra show -json tfplan > infra-plan.json

# Run Conftest
- task: PowerShell@2
  displayName: 'Policy Validation (Conftest)'
  inputs:
    script: |
      conftest test --policy policy infra-plan.json -o json > infra-policy.json
      conftest test --policy policy fabric-plan.json -o json > fabric-policy.json

# Fail on violations (if enforcement enabled)
- task: PowerShell@2
  displayName: 'Enforce Policy Compliance'
  condition: eq(variables['enforcePolicies'], 'true')
  inputs:
    script: |
      $infraResults = Get-Content infra-policy.json | ConvertFrom-Json
      $fabricResults = Get-Content fabric-policy.json | ConvertFrom-Json
      
      $totalFailures = $infraResults.failures.length + $fabricResults.failures.length
      
      if ($totalFailures -gt 0) {
        Write-Error "Policy violations detected: $totalFailures failures"
        exit 1
      }
```

### Pipeline Variable: enforcePolicies

- **`true`**: Fail pipeline on policy violations (production default)
- **`false`**: Audit-only mode (reports generated, pipeline continues)

**Use Cases**:
- `true`: Production deployments, release branches
- `false`: Development branches, experimentation

---

## Writing Custom Policies

### Step-by-Step Guide

#### 1. Create Policy File

```bash
# Create new policy file
touch policy/custom_policy.rego
```

#### 2. Define Package and Rules

```rego
package main

# Import helper functions (optional)
import future.keywords.contains
import future.keywords.if

# Define your policy
deny[msg] {
    # Logic to identify violation
    resource := input.resource_changes[_]
    resource.type == "azurerm_data_factory"
    resource.change.after.public_network_enabled == true
    
    # Error message
    msg := sprintf(
        "Data Factory '%s' must disable public network access",
        [resource.name]
    )
}

# Warning (non-blocking)
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    not resource.change.after.tags.environment
    
    msg := sprintf(
        "Storage account '%s' should have 'environment' tag",
        [resource.name]
    )
}
```

#### 3. Test Locally

```powershell
# Generate plan
terraform -chdir=infra plan -out=tfplan
terraform -chdir=infra show -json tfplan > plan.json

# Test policy
conftest test --policy policy plan.json
```

#### 4. Refine and Iterate

- Review output
- Adjust logic as needed
- Test against multiple scenarios
- Add comments and documentation

### Rego Best Practices

1. **Use Descriptive Messages**: Help developers understand and fix issues
2. **Leverage Iteration**: Use `[_]` for array iteration
3. **Use Helper Functions**: Extract common logic to functions
4. **Comment Complex Logic**: Explain non-obvious policy decisions
5. **Test Thoroughly**: Validate against positive and negative cases

**Reference**: [Rego Style Guide](https://www.openpolicyagent.org/docs/latest/policy-language/#style-guide)

---

## Advanced Policy Techniques

### 1. Helper Functions

```rego
package main

# Helper: Check if resource is being created
is_create(resource) {
    resource.change.actions[_] == "create"
}

# Helper: Check if resource is being updated
is_update(resource) {
    resource.change.actions[_] == "update"
}

# Use helpers in policies
deny[msg] {
    resource := input.resource_changes[_]
    is_create(resource)
    resource.type == "azurerm_storage_account"
    # ... validation logic
}
```

### 2. Conditional Policies Based on Environment

```rego
package main

# Only enforce in production
deny[msg] {
    resource := input.resource_changes[_]
    tags := resource.change.after.tags
    tags.environment == "prod"
    
    # Production-specific checks
    resource.type == "azurerm_storage_account"
    not resource.change.after.redundancy == "GRS"
    
    msg := sprintf(
        "Production storage '%s' must use GRS redundancy",
        [resource.name]
    )
}
```

### 3. External Data

```rego
package main

# Load external data (approved SKUs, regions, etc.)
approved_fabric_skus := data.approved_skus.fabric

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "fabric_capacity"
    sku := resource.change.after.sku.name
    not sku in approved_fabric_skus
    
    msg := sprintf(
        "Fabric capacity SKU '%s' is not approved. Use: %v",
        [sku, approved_fabric_skus]
    )
}
```

---

## Policy Testing

### Unit Testing Policies

Create test files alongside policies:

```rego
# policy/storage_test.rego
package main

test_storage_public_access_denied {
    deny["Storage account 'test-sa' must disable public blob access"] with input as {
        "resource_changes": [{
            "type": "azurerm_storage_account",
            "name": "test-sa",
            "change": {
                "after": {
                    "allow_blob_public_access": true
                }
            }
        }]
    }
}

test_storage_tls_enforced {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "type": "azurerm_storage_account",
            "name": "test-sa",
            "change": {
                "after": {
                    "min_tls_version": "TLS1_2",
                    "enable_https_traffic_only": true,
                    "allow_blob_public_access": false
                }
            }
        }]
    }
}
```

Run tests:
```bash
opa test policy/ -v
```

---

## Next Steps

- [Set Up CI/CD Pipeline](CI-CD-Pipeline)
- [Review Troubleshooting Guide](Troubleshooting)
- [Explore Advanced Usage](Advanced-Usage)

---

[← Back to Home](Home)
