# Compliance & Security

The Azure Data Hub & Microsoft Fabric Terraform Accelerator includes comprehensive compliance and security features, with automated enforcement for HIPAA/HITECH and GDPR regulations.

---

## Automated Compliance Enforcement

### Overview

This accelerator provides **automated compliance enforcement** through Azure Policy initiatives, requiring minimal configuration:

- ✅ **HIPAA/HITECH**: Health Insurance Portability and Accountability Act
- ✅ **GDPR**: General Data Protection Regulation
- ✅ **Automated Remediation**: Managed identity-based policy enforcement
- ✅ **Validation Scripts**: PowerShell-based compliance checking

---

## How Compliance Works

### 1. Enable Compliance in terraform.tfvars

```hcl
# Enable HIPAA compliance
enable_hipaa = true

# Enable GDPR compliance
enable_gdpr  = false

# Scope: "resource_group" or "resource"
compliance_scope = "resource_group"
```

### 2. Policy Initiatives Assigned

When enabled, the accelerator assigns built-in Azure Policy initiatives:

**HIPAA/HITECH Initiative**:
- Policy Definition ID: `/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab`
- Contains: 49 policies covering encryption, access control, auditing, network security

**GDPR Initiative**:
- Policy Definition ID: `/providers/Microsoft.Authorization/policySetDefinitions/3f4f935e-4844-4031-b7c1-8e96b0b34b7c`
- Contains: 23 policies for data protection, privacy, breach notification

**Reference**: [Azure Policy Built-in Initiatives](https://learn.microsoft.com/azure/governance/policy/samples/built-in-initiatives)

### 3. Managed Identity for Remediation

The compliance modules automatically:
- Create a managed identity
- Assign **Contributor** role for remediation
- Configure policy assignment to use the identity
- Enable automatic remediation where supported

### 4. Compliance Scope Options

| Scope | When to Use | Impact |
|-------|-------------|--------|
| `resource_group` | Most common; isolates compliance to RG | Policies apply only to resources in the RG |
| `resource` | Fine-grained control per resource | Policies apply to each individual resource |

---

## Automated Security Controls

When compliance is enabled, the following controls are **automatically configured**:

### Storage Accounts
- ✅ Public blob access disabled
- ✅ TLS 1.2+ enforced
- ✅ Secure transfer required (HTTPS only)
- ✅ Soft delete enabled
- ✅ Diagnostic logging to Log Analytics
- ✅ Encryption at rest (Microsoft-managed keys)

### Key Vault
- ✅ Soft delete enabled (90-day retention)
- ✅ Purge protection enabled
- ✅ Diagnostic logging enabled
- ✅ Network access restrictions (when networking enabled)
- ✅ RBAC-based access (no access policies)

### Networking
- ✅ Network Security Groups (NSGs) configured
- ✅ Service endpoints enabled
- ✅ Public access denied by default (HIPAA mode)
- ✅ NSG flow logs to Log Analytics

### Data Factory
- ✅ Managed identity authentication
- ✅ Diagnostic logging enabled
- ✅ Git integration for version control
- ✅ Network isolation (when VNet enabled)

### Fabric Resources
- ✅ Capacity admin assignment validated
- ✅ Workspace access controlled via RBAC
- ✅ Integration with Azure AD for authentication

---

## Post-Deployment Lockdown

### HIPAA Storage Lockdown Script

After deployment, run the PowerShell lockdown script for additional HIPAA controls:

```powershell
./scripts/lockdown_storage.ps1 `
    -StorageAccountName "<storage-name>" `
    -ResourceGroupName "<rg-name>"
```

**What It Does**:
- Disables public network access entirely
- Configures firewall rules (if specified)
- Validates configuration against HIPAA requirements
- Outputs compliance status

**When to Run**:
- Immediately after infrastructure deployment
- After any storage configuration changes
- As part of compliance validation workflow

---

## Compliance Validation

### Validation Script

Check compliance status post-deployment:

```powershell
./scripts/validate-compliance.ps1 `
    -ScopeId "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
```

### Sample Output

```
========================================
Azure Policy Compliance Report
========================================
Scope: /subscriptions/xxx.../resourceGroups/acme-dev-rg
Generated: 2026-02-11 18:00:00 UTC

HIPAA/HITECH Compliance: 94% (46/49 policies)
  ✅ Compliant: 46 policies
  ❌ Non-Compliant: 3 policies
  ⏳ Not Evaluated: 0 policies

GDPR Compliance: N/A (not enabled)

Non-Compliant Resources:
  [HIPAA] Storage 'acmedevsa'
    - Policy: "Storage accounts should have private endpoint"
    - Reason: No private endpoint configured
    - Remediation: Configure private endpoint via Azure Portal or Terraform

  [HIPAA] Data Factory 'acme-dev-adf'
    - Policy: "Public network access should be disabled"
    - Reason: Public network access is enabled
    - Remediation: Set publicNetworkAccess = "Disabled" in Terraform

  [HIPAA] Key Vault 'acme-dev-kv'
    - Policy: "Soft delete should be enabled"
    - Reason: Soft delete not configured
    - Remediation: Auto-remediation available; trigger policy evaluation

Recommendations:
  1. Configure private endpoints for storage account
  2. Review Data Factory networking settings
  3. Trigger auto-remediation for Key Vault soft delete

========================================
```

### Azure Portal Validation

1. Navigate to **Azure Portal** → **Policy**
2. Select **Compliance** in left menu
3. Filter by resource group or subscription
4. Review compliance state for HIPAA/GDPR initiatives
5. Click on policies for remediation guidance

---

## Security Best Practices

### 1. Principle of Least Privilege

✅ **Use Role-Based Access Control (RBAC)**:
```hcl
# Grant specific role to managed identity
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}
```

❌ **Avoid Using Access Keys**:
- Prefer managed identities
- Rotate keys if absolutely necessary
- Store keys in Key Vault, never in code

### 2. Network Isolation

✅ **Use Private Endpoints**:
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

✅ **Configure Network Security Groups**:
- Allow only required traffic
- Log denied traffic to Log Analytics
- Use service tags for Azure services

### 3. Secrets Management

✅ **Store in Key Vault**:
```powershell
# Store secret
Set-AzKeyVaultSecret `
    -VaultName "acme-dev-kv" `
    -Name "database-password" `
    -SecretValue (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force)

# Reference in Terraform
data "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  key_vault_id = module.key_vault.id
}
```

❌ **Never Hardcode**:
```hcl
# ❌ BAD: Hardcoded secret
resource "azurerm_mssql_server" "bad" {
  administrator_login_password = "MyPassword123"  # NEVER DO THIS!
}

# ✅ GOOD: Reference from Key Vault
resource "azurerm_mssql_server" "good" {
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value
}
```

### 4. Encryption

✅ **Enable Encryption at Rest**:
- Storage: Enabled by default (Microsoft-managed keys)
- SQL: Transparent Data Encryption (TDE) enabled
- Disk: Azure Disk Encryption for VMs

✅ **Enforce Encryption in Transit**:
```hcl
resource "azurerm_storage_account" "example" {
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
}
```

### 5. Audit Logging

✅ **Enable Diagnostic Settings**:
```hcl
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "storage-diagnostics"
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

**Reference**: [Azure Monitor Diagnostic Settings](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings)

---

## Extending Compliance

### Adding Custom Compliance Standards

To add additional compliance standards (PCI-DSS, SOC 2, ISO 27001):

#### 1. Create New Compliance Module

```
modules/compliance/pci_dss/
├── main.tf
├── variables.tf
└── outputs.tf
```

#### 2. Define Policy Assignment

```hcl
# modules/compliance/pci_dss/main.tf
resource "azurerm_resource_group_policy_assignment" "pci_dss" {
  name                 = "pci-dss-assignment"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "<pci-dss-initiative-id>"

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}
```

#### 3. Reference in Root main.tf

```hcl
# infra/main.tf
module "pci_dss_compliance" {
  source = "../modules/compliance/pci_dss"
  count  = var.enable_pci_dss ? 1 : 0

  resource_group_id = module.resource_group.id
  location          = var.location
}
```

#### 4. Add Validation to PowerShell Script

```powershell
# scripts/validate-compliance.ps1
if ($EnablePCIDSS) {
    $pciCompliance = Get-AzPolicyState -Filter "PolicyDefinitionName eq 'PCI-DSS'"
    Write-Output "PCI-DSS Compliance: $($pciCompliance.CompliancePercentage)%"
}
```

---

## Compliance Checklist

Use this checklist for compliance verification:

### HIPAA Compliance Checklist

- [ ] Storage accounts have public access disabled
- [ ] TLS 1.2+ enforced on all services
- [ ] Diagnostic logging enabled for all resources
- [ ] Network isolation configured (VNets, NSGs)
- [ ] Audit logging to Log Analytics
- [ ] Soft delete enabled on Key Vault
- [ ] Managed identities used (no access keys)
- [ ] Encryption at rest enabled
- [ ] Regular compliance validation (weekly/monthly)
- [ ] Security patches applied regularly

### GDPR Compliance Checklist

- [ ] Data classification completed
- [ ] Personal data identified and tagged
- [ ] Data retention policies configured
- [ ] Right to erasure capability implemented
- [ ] Data breach notification process defined
- [ ] Privacy impact assessment completed
- [ ] Consent management implemented
- [ ] Data processing agreements signed
- [ ] Regular compliance audits scheduled
- [ ] Data subject access request (DSAR) process defined

---

## Important Disclaimer

> ⚠️ **Compliance Responsibility**
>
> This accelerator provides a **strong starting point** for compliance automation, but is **NOT a complete end-to-end compliance solution**. Organizations must:
>
> - ✅ Review assigned policies in Azure Portal
> - ✅ Run validation scripts to identify gaps
> - ✅ Manually remediate non-compliant resources
> - ✅ Extend the solution for organization-specific requirements
> - ✅ Engage compliance professionals for certification
> - ✅ Conduct regular compliance audits
> - ✅ Maintain documentation and evidence
> - ✅ Train staff on compliance requirements
>
> **This solution is a technical control framework, not legal or regulatory advice.**

**Reference**: [Microsoft Azure Compliance Documentation](https://learn.microsoft.com/azure/compliance/)

---

## Compliance Resources

| Standard | Azure Documentation | Policy Initiative |
|----------|---------------------|-------------------|
| **HIPAA/HITECH** | [HIPAA on Azure](https://learn.microsoft.com/azure/compliance/offerings/offering-hipaa-us) | Built-in |
| **GDPR** | [GDPR on Azure](https://learn.microsoft.com/azure/compliance/offerings/offering-gdpr) | Built-in |
| **PCI-DSS** | [PCI-DSS on Azure](https://learn.microsoft.com/azure/compliance/offerings/offering-pci-dss) | Built-in |
| **SOC 2** | [SOC 2 on Azure](https://learn.microsoft.com/azure/compliance/offerings/offering-soc-2) | Custom |
| **ISO 27001** | [ISO 27001 on Azure](https://learn.microsoft.com/azure/compliance/offerings/offering-iso-27001) | Built-in |

---

## Next Steps

- [Configure Policy-as-Code](Policy-as-Code-with-OPA)
- [Set Up CI/CD Pipeline](CI-CD-Pipeline)
- [Review Security Best Practices](Best-Practices)

---

[← Back to Home](Home)
