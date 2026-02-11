# Best Practices

This guide provides best practices for using the Azure Data Hub & Microsoft Fabric Terraform Accelerator effectively and securely.

---

## Terraform Best Practices

### 1. Use Modules for Reusability

✅ **DO**: Encapsulate reusable patterns in modules
```hcl
module "storage_medallion" {
  source = "../modules/storage_medallion"
  
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags
}
```

❌ **DON'T**: Duplicate resource definitions across environments

**Reference**: [HashiCorp Module Development](https://developer.hashicorp.com/terraform/tutorials/modules)

### 2. Version Lock Providers

✅ **DO**: Pin provider versions for consistency
```hcl
terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"  # Lock minor version
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 0.1.0"
    }
  }
}
```

❌ **DON'T**: Use unpinned versions in production

### 3. Use Remote State with Locking

✅ **DO**: Store state in Azure Storage with locking
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstatestg"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

**Benefits**:
- Team collaboration
- State locking (prevents conflicts)
- Encryption at rest
- Version history

**Reference**: [Terraform AzureRM Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

### 4. Separate Environments

✅ **DO**: Use workspaces or separate state files
```powershell
# Workspace approach
terraform workspace new dev
terraform workspace new prod

# Or separate directories
terraform -chdir=environments/dev apply
terraform -chdir=environments/prod apply
```

### 5. Plan Before Apply

✅ **ALWAYS**: Review plan output before applying
```powershell
# Save plan
terraform plan -out=tfplan -var-file=terraform.tfvars

# Review plan
terraform show tfplan

# Apply only if plan looks correct
terraform apply tfplan
```

### 6. Use Variables, Not Hardcoded Values

✅ **DO**: Parameterize everything
```hcl
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}
```

❌ **DON'T**: Hardcode values
```hcl
resource "azurerm_resource_group" "bad" {
  name     = "acme-dev-rg"  # ❌ Hardcoded
  location = "eastus"       # ❌ Hardcoded
}
```

### 7. Output Important Values

✅ **DO**: Expose resource IDs and properties
```hcl
output "storage_account_name" {
  description = "Name of the medallion storage account"
  value       = azurerm_storage_account.main.name
}

output "fabric_workspace_id" {
  description = "ID of the Fabric workspace"
  value       = module.fabric_workspace.id
}
```

### 8. Use Data Sources for Existing Resources

✅ **DO**: Query existing resources
```hcl
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

resource "azurerm_storage_account" "new" {
  resource_group_name = data.azurerm_resource_group.existing.name
  # ...
}
```

### 9. Enable Debug Logging When Troubleshooting

```powershell
# Enable detailed logging
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "terraform-debug.log"

# Run terraform command
terraform plan

# Disable when done
$env:TF_LOG = ""
```

**Reference**: [Terraform Debugging](https://developer.hashicorp.com/terraform/internals/debugging)

### 10. Use Lifecycle Rules Carefully

```hcl
resource "azurerm_storage_account" "main" {
  # ... configuration

  lifecycle {
    prevent_destroy = true  # Protect production data
    ignore_changes  = [tags["created_date"]]  # Ignore automated tag updates
  }
}
```

---

## Azure Best Practices

### 1. Resource Naming Conventions

✅ **DO**: Follow consistent naming patterns
```
Resource Type        Pattern                         Example
-------------        -------                         -------
Resource Group       {prefix}-{env}-rg               acme-dev-rg
Storage Account      {prefix}{env}sa                 acmedevsa
Data Factory         {prefix}-{env}-adf              acme-dev-adf
Key Vault            {prefix}-{env}-kv               acme-dev-kv
Fabric Capacity      {prefix}{env}fabriccapacity     acmedevfabriccapacity
```

**Reference**: [Azure Naming Conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

### 2. Resource Tagging Strategy

✅ **DO**: Tag all resources consistently
```hcl
tags = {
  project     = "${var.company_name}-${var.project_name}"
  owner       = "data-platform-team"
  cost_center = "engineering"
  environment = var.environment
  managed_by  = "terraform"
  created_date = timestamp()
}
```

**Recommended Tags**:
- `project`: Project identifier
- `owner`: Team or individual responsible
- `cost_center`: Billing allocation
- `environment`: dev, qa, prod
- `managed_by`: terraform, manual, etc.

### 3. Use RBAC, Not Access Keys

✅ **DO**: Use managed identities and RBAC
```hcl
resource "azurerm_user_assigned_identity" "example" {
  name                = "${var.prefix}-${var.environment}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}
```

❌ **DON'T**: Use access keys when managed identity is available

### 4. Network Isolation

✅ **DO**: Use private endpoints for data services
```hcl
resource "azurerm_private_endpoint" "storage" {
  name                = "${var.prefix}-storage-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.prefix}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
```

### 5. Enable Diagnostic Settings

✅ **DO**: Send logs to Log Analytics
```hcl
resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "${var.prefix}-diagnostics"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "StorageRead"
    enabled  = true
  }

  log {
    category = "StorageWrite"
    enabled  = true
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}
```

### 6. Cost Optimization

✅ **DO**: Use appropriate SKUs and tiers
- Development: Use lower-tier SKUs (F2, F4 for Fabric)
- Production: Right-size based on actual workload
- Storage: Use lifecycle policies to tier old data

✅ **DO**: Set budgets and alerts
```powershell
# Create budget via Azure CLI
az consumption budget create `
    --budget-name "monthly-budget" `
    --amount 1000 `
    --time-grain Monthly `
    --start-date 2026-01-01 `
    --end-date 2026-12-31
```

### 7. High Availability

✅ **DO**: Deploy across availability zones (where supported)
```hcl
resource "azurerm_storage_account" "main" {
  account_replication_type = "GZRS"  # Geo-zone-redundant storage
  # ... other configuration
}
```

### 8. Backup and Disaster Recovery

✅ **DO**: Configure backups
- Storage: Enable soft delete and versioning
- Key Vault: Enable soft delete and purge protection
- Databases: Configure automated backups

---

## PowerShell Best Practices

### 1. Use Approved Verbs

✅ **DO**: Follow PowerShell verb conventions
```powershell
function Get-ComplianceReport { }    # ✅
function Set-StorageLockdown { }     # ✅
function New-FabricLakehouse { }     # ✅
function Remove-OldResources { }     # ✅
```

❌ **DON'T**: Use non-standard verbs
```powershell
function Fetch-ComplianceReport { }  # ❌
function Change-StorageSettings { }  # ❌
```

**Reference**: [Approved Verbs](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)

### 2. Enable CmdletBinding and Parameter Validation

```powershell
function Set-StorageLockdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName
    )
    
    # Function logic
}
```

### 3. Implement Error Handling

```powershell
try {
    $result = Get-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName `
        -ErrorAction Stop
}
catch {
    Write-Error "Failed to get storage account: $($_.Exception.Message)"
    exit 1
}
```

### 4. Add Comment-Based Help

```powershell
<#
.SYNOPSIS
    Locks down storage account for HIPAA compliance.

.DESCRIPTION
    Disables public network access and configures firewall rules.

.PARAMETER StorageAccountName
    Name of the storage account.

.EXAMPLE
    Set-StorageLockdown -StorageAccountName "acmedevsa" -ResourceGroupName "acme-dev-rg"
#>
```

### 5. Use Secure Strings for Secrets

```powershell
# ✅ DO: Use secure string
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

# ✅ BETTER: Get from Key Vault
$secret = Get-AzKeyVaultSecret -VaultName "my-vault" -Name "db-password"
$securePassword = $secret.SecretValue
```

---

## Security Best Practices

### 1. Secrets Management

✅ **DO**: Store in Key Vault
```powershell
# Store secret
Set-AzKeyVaultSecret `
    -VaultName "acme-dev-kv" `
    -Name "db-password" `
    -SecretValue (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force)

# Reference in Terraform
data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = module.key_vault.id
}
```

❌ **DON'T**: Hardcode secrets in Terraform or scripts

### 2. Principle of Least Privilege

✅ **DO**: Grant minimum required permissions
```hcl
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"  # Specific role
  principal_id         = var.managed_identity_id
}
```

❌ **DON'T**: Grant broad permissions like Owner or Contributor unless necessary

### 3. Regular Security Audits

✅ **DO**: Run compliance validation regularly
```powershell
# Weekly compliance check
./scripts/validate-compliance.ps1 `
    -ScopeId "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
```

### 4. Enable Multi-Factor Authentication

✅ **DO**: Require MFA for all admin accounts
- Azure AD Conditional Access policies
- Service principal client secrets rotated regularly

### 5. Audit Logging

✅ **DO**: Enable logging for all resources
- Storage: Blob read/write logs
- Key Vault: Secret access logs
- Data Factory: Pipeline execution logs
- Azure AD: Sign-in and audit logs

---

## CI/CD Best Practices

### 1. Use Separate Service Principals

✅ **DO**: Different SPs for different environments
```
dev-terraform-sp   → Dev subscription
qa-terraform-sp    → QA subscription
prod-terraform-sp  → Prod subscription
```

### 2. Protect Sensitive Variables

✅ **DO**: Use pipeline secrets/variable groups
```yaml
variables:
  - group: 'terraform-secrets'  # Variable group with secret values
```

### 3. Require Approvals for Production

✅ **DO**: Manual approval for prod deployments
```yaml
- stage: Production
  dependsOn: QA
  jobs:
  - deployment: DeployProd
    environment: production  # Requires manual approval
```

### 4. Run Policy Validation

✅ **DO**: Always run Conftest in pipelines
```yaml
- task: PowerShell@2
  displayName: 'Policy Validation'
  inputs:
    script: |
      conftest test --policy policy plan.json
      if ($LASTEXITCODE -ne 0) { exit 1 }
```

### 5. Store State Remotely

✅ **DO**: Use Azure Storage backend
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstatestg"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

---

## Performance Best Practices

### 1. Use Parallel Execution

✅ **DO**: Enable parallel resource creation
```hcl
resource "azurerm_storage_container" "bronze" {
  name = "bronze"
  # ...
}

resource "azurerm_storage_container" "silver" {
  name = "silver"
  # ... no dependency on bronze
}

# These will be created in parallel
```

### 2. Minimize Provider API Calls

✅ **DO**: Use data sources sparingly
```hcl
# ✅ Good: Query once, reuse
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_role_assignment" "main" {
  # Reuse same data source
  principal_id = data.azurerm_client_config.current.object_id
}
```

### 3. Right-Size Fabric Capacity

✅ **DO**: Choose appropriate SKU
- Development: F2, F4
- Small production: F8, F16
- Medium production: F32, F64
- Large production: F128+

### 4. Use Storage Lifecycle Policies

✅ **DO**: Tier old data automatically
```hcl
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "tier-to-cool"
    enabled = true
    
    filters {
      blob_types = ["blockBlob"]
    }
    
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }
}
```

---

## Disaster Recovery Best Practices

### 1. Regular Backups

✅ **DO**: Enable soft delete on critical resources
```hcl
resource "azurerm_key_vault" "main" {
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
}

resource "azurerm_storage_account" "main" {
  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
}
```

### 2. Geographic Redundancy

✅ **DO**: Use GRS for production storage
```hcl
resource "azurerm_storage_account" "prod" {
  account_replication_type = "GRS"  # Geo-redundant
}
```

### 3. Document Recovery Procedures

✅ **DO**: Maintain runbooks for common scenarios
- Storage account deletion
- Accidental data deletion
- Region outage
- Service principal compromise

### 4. Test Recovery Procedures

✅ **DO**: Regular DR drills (quarterly)
- Restore from backup
- Failover to secondary region
- Re-deploy infrastructure from scratch

---

## Next Steps

- [Explore Troubleshooting Guide](Troubleshooting)
- [Review Advanced Usage Scenarios](Advanced-Usage)
- [Learn About Contributing](Contributing)

---

[← Back to Home](Home)
