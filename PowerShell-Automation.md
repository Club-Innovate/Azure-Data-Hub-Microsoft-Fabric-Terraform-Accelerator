# PowerShell Automation

Microsoft PowerShell serves as the automation and orchestration layer for the Azure Data Hub & Microsoft Fabric Terraform Accelerator.

## Why PowerShell?

**PowerShell** was chosen for automation because:

- ✅ **Native Azure Integration**: Azure PowerShell modules for seamless cloud operations
- ✅ **Cross-Platform**: Runs on Windows, macOS, and Linux (PowerShell 7+)
- ✅ **Rich Object Model**: Work with .NET objects, not just text parsing
- ✅ **Zero Cost**: Included with Windows, free download for other platforms
- ✅ **Terraform Integration**: Perfect complement for pre/post-deployment tasks
- ✅ **Enterprise Adoption**: Widely used in Windows-centric enterprises

**Reference**: [Microsoft PowerShell Documentation](https://learn.microsoft.com/powershell/)

---

## Script Catalog

Scripts are organized into two directories:

### Root `scripts/` Directory

Scripts for deployment, compliance, and testing:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `lockdown_storage.ps1` | Enforce HIPAA storage lockdown | After deployment (HIPAA mode) |
| `validate-compliance.ps1` | Check Azure Policy compliance | Post-deployment, periodic audits |
| `test_integration.ps1` | Full integration test | CI/CD, pre-production validation |
| `test_smoke.ps1` | Safe plan-only test | PR validation, structure checks |
| `check_purview.ps1` | Query existing Purview accounts | Pre-deployment validation |

### Fabric `fabric/scripts/` Directory

Scripts for Microsoft Fabric operations:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `create_fabric_lakehouse.ps1` | Create lakehouse via REST API | Post-deployment, lakehouse provisioning |
| `add_workspace_admin.ps1` | Add admin to Fabric workspace | User management |
| `fabric_notebook_utils.ps1` | Notebook helper functions | Called by other scripts |
| `_verify_notebook.ps1` | Verify notebook JSON structure | Development/testing |

---

## Script Documentation

### 1. lockdown_storage.ps1

**Purpose**: Enforces HIPAA-compliant storage security by disabling public network access.

**Parameters**:
```powershell
-StorageAccountName  # Name of the storage account
-ResourceGroupName   # Resource group containing the storage account
```

**Usage**:
```powershell
./scripts/lockdown_storage.ps1 `
    -StorageAccountName "acmedevsa" `
    -ResourceGroupName "acme-dev-rg"
```

**What It Does**:
1. Disables public blob access
2. Sets default network action to Deny
3. Configures firewall rules (if specified)
4. Validates configuration
5. Outputs compliance status

**When to Run**:
- Immediately after infrastructure deployment (HIPAA mode)
- After any storage configuration changes
- As part of compliance validation workflow

**Reference**: [Azure Storage Security Best Practices](https://learn.microsoft.com/azure/storage/common/storage-security-guide)

---

### 2. validate-compliance.ps1

**Purpose**: Validates Azure Policy compliance status for HIPAA and GDPR policies.

**Parameters**:
```powershell
-ScopeId  # Azure resource scope (/subscriptions/.../resourceGroups/...)
```

**Usage**:
```powershell
./scripts/validate-compliance.ps1 `
    -ScopeId "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
```

**Sample Output**:
```
========================================
Azure Policy Compliance Report
========================================
Scope: /subscriptions/xxx/resourceGroups/acme-dev-rg
Generated: 2026-02-11 18:00:00 UTC

HIPAA/HITECH Compliance: 94% (46/49 policies)
GDPR Compliance: N/A (not enabled)

Non-Compliant Resources:
  [HIPAA] Storage 'acmedevsa' - Missing private endpoint
  [HIPAA] Data Factory 'acme-dev-adf' - Public network access enabled
  [HIPAA] Key Vault 'acme-dev-kv' - Soft delete not configured

Recommendations:
  1. Configure private endpoints for storage account
  2. Review Data Factory networking settings
  3. Enable Key Vault soft delete (auto-remediation available)

========================================
```

**When to Run**:
- Post-deployment validation
- Weekly compliance audits
- Before production releases
- After configuration changes

---

### 3. test_integration.ps1

**Purpose**: Full end-to-end integration test including deployment and policy validation.

**Parameters**:
```powershell
-SkipDestroy  # Optional: Skip terraform destroy at end
```

**Usage**:
```powershell
# Full test (creates and destroys resources)
./scripts/test_integration.ps1

# Skip destroy for manual inspection
./scripts/test_integration.ps1 -SkipDestroy
```

**Test Flow**:
1. ✅ Validate repository structure
2. ✅ Terraform init (infra + fabric)
3. ✅ Terraform plan (infra + fabric)
4. ✅ Terraform apply (infra + fabric)
5. ✅ Policy validation (Conftest)
6. ✅ Compliance check
7. ✅ Terraform destroy (unless -SkipDestroy)

**When to Run**:
- CI/CD pipeline (automated testing)
- Pre-release validation
- Major configuration changes
- ⚠️ **Use test subscription only!**

---

### 4. test_smoke.ps1

**Purpose**: Safe, plan-only smoke test without creating resources.

**Usage**:
```powershell
./scripts/test_smoke.ps1
```

**What It Does**:
1. Validates directory structure
2. Checks for required files
3. Runs `terraform validate`
4. Runs `terraform plan` (no apply!)
5. Runs policy checks with Conftest
6. Reports results

**When to Run**:
- Pull request validation
- Pre-commit checks
- Configuration syntax validation
- Safe to run in production subscription (no resources created)

---

### 5. create_fabric_lakehouse.ps1

**Purpose**: Creates a Microsoft Fabric Lakehouse using the Fabric REST API.

**Parameters**:
```powershell
-TenantId       # Azure AD tenant ID
-ClientId       # Service principal application ID
-ClientSecret   # Service principal password
-WorkspaceId    # Fabric workspace GUID
-LakehouseName  # Name for the lakehouse
```

**Usage**:
```powershell
./fabric/scripts/create_fabric_lakehouse.ps1 `
    -TenantId "<tenant-id>" `
    -ClientId "<app-id>" `
    -ClientSecret "<secret>" `
    -WorkspaceId "<workspace-guid>" `
    -LakehouseName "acme_dev_lakehouse"
```

**Why PowerShell for Fabric?**
- Terraform Fabric provider has limited resource coverage
- PowerShell provides full REST API access
- Enables advanced operations (notebooks, semantic models, pipelines)

**Reference**: [Microsoft Fabric REST API](https://learn.microsoft.com/rest/api/fabric/)

---

### 6. add_workspace_admin.ps1

**Purpose**: Adds a user or service principal as admin to a Fabric workspace.

**Parameters**:
```powershell
-WorkspaceId   # Fabric workspace GUID
-UserToAdd     # User UPN or object ID
-AccessRight   # Admin, Member, Contributor, Viewer
-PrincipalType # User, ServicePrincipal
```

**Usage**:
```powershell
./fabric/scripts/add_workspace_admin.ps1 `
    -WorkspaceId "<workspace-guid>" `
    -UserToAdd "user@domain.com" `
    -AccessRight "Admin" `
    -PrincipalType "User"
```

**When to Use**:
- Onboarding new team members
- Granting service principal access
- Changing permission levels
- Automated user provisioning

---

## PowerShell Best Practices

### 1. Use Approved Verbs

Follow PowerShell verb conventions:

```powershell
# ✅ Good
Get-AzResource
Set-AzStorageAccount
New-AzResourceGroup
Remove-AzKeyVault

# ❌ Bad
Fetch-AzResource
Change-AzStorageAccount
Create-AzResourceGroup
Delete-AzKeyVault
```

**Reference**: [Approved Verbs for PowerShell Commands](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)

### 2. Enable CmdletBinding

```powershell
function Get-ComplianceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScopeId
    )
    
    # Function logic here
}
```

### 3. Use Parameter Validation

```powershell
param(
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    
    [ValidateSet("Standard_LRS", "Standard_GRS", "Premium_LRS")]
    [string]$SKU = "Standard_LRS",
    
    [ValidateRange(30, 365)]
    [int]$RetentionDays = 90
)
```

### 4. Implement Proper Error Handling

```powershell
try {
    $storageAccount = Get-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName `
        -ErrorAction Stop
}
catch {
    Write-Error "Failed to get storage account: $_"
    exit 1
}
```

### 5. Add Comment-Based Help

```powershell
<#
.SYNOPSIS
    Locks down a storage account for HIPAA compliance.

.DESCRIPTION
    Disables public network access and configures firewall rules
    for an Azure Storage account to meet HIPAA requirements.

.PARAMETER StorageAccountName
    Name of the Azure Storage account to lock down.

.PARAMETER ResourceGroupName
    Name of the resource group containing the storage account.

.EXAMPLE
    ./lockdown_storage.ps1 -StorageAccountName "acmedevsa" -ResourceGroupName "acme-dev-rg"
    
    Locks down the storage account 'acmedevsa' in resource group 'acme-dev-rg'.

.NOTES
    Author: Hans Esquivel
    Version: 1.0
#>
```

**Reference**: [PowerShell Comment-Based Help](https://learn.microsoft.com/powershell/scripting/developer/help/writing-comment-based-help-topics)

### 6. Use Secure String for Secrets

```powershell
# ✅ Good: Secure string
$securePassword = ConvertTo-SecureString -String $PlainTextPassword -AsPlainText -Force

# ✅ Better: From Key Vault
$secret = Get-AzKeyVaultSecret -VaultName "my-vault" -Name "db-password"
$securePassword = $secret.SecretValue

# ❌ Bad: Plain text
$password = "MyPassword123"
```

---

## Integrating PowerShell with Terraform

### Use Case 1: Pre-Deployment Validation

```hcl
# Check for existing resources before deployment
data "external" "purview_check" {
  program = ["pwsh", "-File", "./scripts/check_purview.ps1"]
  
  query = {
    subscription_id = var.subscription_id
    tenant_id       = var.tenant_id
    client_id       = var.client_id
    client_secret   = var.client_secret
  }
}
```

### Use Case 2: Post-Deployment Configuration

Use `null_resource` with `local-exec`:

```hcl
resource "null_resource" "lockdown_storage" {
  depends_on = [module.storage_medallion]
  
  provisioner "local-exec" {
    command = <<EOT
      pwsh -File ./scripts/lockdown_storage.ps1 `
        -StorageAccountName ${module.storage_medallion.storage_account_name} `
        -ResourceGroupName ${module.resource_group.name}
    EOT
  }
  
  triggers = {
    storage_id = module.storage_medallion.storage_account_id
  }
}
```

**Reference**: [Terraform External Data Source](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external)

---

## Common PowerShell Commands for Azure

### Azure Resource Management

```powershell
# List all resource groups
Get-AzResourceGroup | Select-Object ResourceGroupName, Location

# List resources in a resource group
Get-AzResource -ResourceGroupName "acme-dev-rg" | Format-Table

# Get resource details
$resource = Get-AzResource -ResourceId "<resource-id>"
$resource | Format-List

# Delete a resource group (careful!)
Remove-AzResourceGroup -Name "acme-dev-rg" -Force
```

### Storage Operations

```powershell
# Get storage account
$storage = Get-AzStorageAccount -ResourceGroupName "acme-dev-rg" -Name "acmedevsa"

# List containers
$ctx = $storage.Context
Get-AzStorageContainer -Context $ctx

# Upload blob
Set-AzStorageBlobContent -File "data.csv" -Container "bronze" -Blob "data.csv" -Context $ctx

# Set network rules
Update-AzStorageAccountNetworkRuleSet `
    -ResourceGroupName "acme-dev-rg" `
    -Name "acmedevsa" `
    -DefaultAction Deny
```

### Policy Compliance

```powershell
# Get policy compliance state
Get-AzPolicyState -ResourceGroupName "acme-dev-rg"

# Get specific policy assignment
Get-AzPolicyAssignment -Scope "/subscriptions/<sub-id>/resourceGroups/<rg>"

# Trigger compliance evaluation
Start-AzPolicyComplianceScan -ResourceGroupName "acme-dev-rg"
```

---

## Next Steps

- [Explore Compliance & Security Features](Compliance-and-Security)
- [Set Up CI/CD Pipeline](CI-CD-Pipeline)
- [Review Troubleshooting Guide](Troubleshooting)

---

[← Back to Home](Home)
