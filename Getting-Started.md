# Getting Started

This guide will help you deploy the Azure Data Hub & Microsoft Fabric Terraform Accelerator from scratch.

## Prerequisites

Before deploying this accelerator, ensure you have:

### Required Tools

1. **HashiCorp Terraform** v1.3+ (tested with 1.5.x)
   - Download: [https://developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
   - Free, open-source version (no license required)

2. **Microsoft PowerShell** 7.0+
   - Windows: Pre-installed (or download from Microsoft)
   - macOS/Linux: [https://learn.microsoft.com/powershell/scripting/install/installing-powershell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)

3. **Azure CLI** (optional, for authentication)
   - Download: [https://learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli)

4. **Conftest** (for Policy-as-Code validation)
   - Download: [https://www.conftest.dev](https://www.conftest.dev)

### Azure Requirements

- **Azure Subscription**: Active subscription with resource creation permissions
- **Service Principal**: With `Contributor` role on subscription
- **Azure AD Permissions**: Ability to assign Fabric admin roles

## Creating a Service Principal

Use Azure CLI or PowerShell to create a service principal:

### PowerShell Method

```powershell
# Login to Azure
Connect-AzAccount

# Create service principal
$sp = New-AzADServicePrincipal -DisplayName "fabric-terraform-sp" `
    -Role "Contributor" `
    -Scope "/subscriptions/<subscription-id>"

# Capture credentials
$sp.AppId          # ARM_CLIENT_ID
$sp.PasswordCredentials.SecretText  # ARM_CLIENT_SECRET
```

**Reference**: [Microsoft PowerShell Azure AD Module](https://learn.microsoft.com/powershell/module/azuread/)

### Azure CLI Method

```bash
az ad sp create-for-rbac \
  --name "fabric-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>
```

### Get Service Principal Object ID

```powershell
# PowerShell
Get-AzADServicePrincipal -ApplicationId "<app-id>" | Select-Object Id

# Azure CLI
az ad sp show --id <app-id> --query objectId -o tsv
```

**Reference**: [HashiCorp Terraform Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)

## Quick Start Guide

### 1. Clone the Repository

```bash
git clone https://github.com/Club-Innovate/Azure-Data-Hub-Microsoft-Fabric-Terraform-Accelerator.git
cd Azure-Data-Hub-Microsoft-Fabric-Terraform-Accelerator
```

### 2. Configure Variables

Copy the example configuration and customize for your organization:

```powershell
# PowerShell
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars  # Edit with your values
```

**Key Variables to Configure:**

```hcl
# Azure credentials
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"
client_id       = "your-service-principal-app-id"
client_secret   = "your-service-principal-secret"

# Organization identity
prefix       = "acme"           # Lowercase, alphanumeric
company_name = "Acme Corp"      # Display name
project_name = "DataHub"        # Project identifier
environment  = "dev"            # dev, qa, prod

# Module toggles
enable_fabric            = true
enable_storage_medallion = true
enable_purview           = false
enable_data_factory      = true
enable_api_management    = false  # Long provisioning time!

# Compliance
enable_hipaa = true
enable_gdpr  = false
compliance_scope = "resource_group"
```

### 3. Set Environment Variables

**PowerShell:**
```powershell
$env:ARM_CLIENT_ID     = "<service-principal-app-id>"
$env:ARM_CLIENT_SECRET = "<service-principal-password>"
$env:ARM_TENANT_ID     = "<aad-tenant-id>"
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
```

**Bash:**
```bash
export ARM_CLIENT_ID="<service-principal-app-id>"
export ARM_CLIENT_SECRET="<service-principal-password>"
export ARM_TENANT_ID="<aad-tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

**Reference**: [Microsoft PowerShell Environment Variables](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_environment_variables)

### 4. Deploy Infrastructure

**Recommended: Two-Phase Deployment**

This accelerator uses a **two-root Terraform structure** for optimal dependency management:

```powershell
# Navigate to repository root
cd Azure-Data-Hub-Microsoft-Fabric-Terraform-Accelerator

# Phase 1: Deploy Azure Infrastructure
terraform -chdir=infra init
terraform -chdir=infra plan -out=tfplan -var-file=../terraform.tfvars
terraform -chdir=infra apply tfplan

# Phase 2: Deploy Microsoft Fabric Resources
terraform -chdir=fabric init
terraform -chdir=fabric plan -out=tfplan -var-file=../terraform.tfvars
terraform -chdir=fabric apply tfplan
```

**Why Two Roots?**
- **Dependency Separation**: Fabric resources depend on Azure infrastructure
- **Provider Isolation**: Different provider versions/configurations
- **Deployment Flexibility**: Deploy infra and fabric independently
- **Faster Iterations**: Modify Fabric without re-planning entire infrastructure

**Reference**: [HashiCorp Terraform Directory Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)

### 5. Verify Deployment

```powershell
# Check Azure resources
az resource list --resource-group <prefix>-<env>-rg --output table

# Run smoke test
./scripts/test_smoke.ps1

# Validate compliance (if enabled)
./scripts/validate-compliance.ps1 -ScopeId "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
```

## What Gets Deployed

After successful deployment, you will have:

✅ **Resource Group**: Containing all Azure resources  
✅ **Virtual Network**: With subnets and NSGs (if enabled)  
✅ **Storage Account**: ADLS Gen2 with Bronze/Silver/Gold containers  
✅ **Key Vault**: For secrets management  
✅ **Data Factory**: For ETL/ELT pipelines  
✅ **Log Analytics**: Centralized logging  
✅ **Fabric Capacity**: Compute resources for Fabric  
✅ **Fabric Workspace**: Collaboration environment  
✅ **Fabric Lakehouse**: SQL-queryable data storage (if enabled)  
✅ **Compliance Policies**: HIPAA/GDPR policy assignments (if enabled)  

## Next Steps

- [Explore Core Components](Core-Components)
- [Configure Compliance](Compliance-and-Security)
- [Set Up CI/CD Pipeline](CI-CD-Pipeline)
- [Review Best Practices](Best-Practices)

---

[← Back to Home](Home)
