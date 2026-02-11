# Core Components

This page provides detailed documentation for each core component of the Azure Data Hub & Microsoft Fabric Terraform Accelerator.

## 1. Azure Storage (Medallion Architecture)

**Module**: `modules/storage_medallion`

### Overview

Implements a three-tier data lake using **Azure Data Lake Storage Gen2** following the Medallion Architecture pattern:

- **Bronze Container**: Raw data ingestion from source systems
- **Silver Container**: Cleaned, validated, and conformed data
- **Gold Container**: Business-ready, aggregated datasets

### Features

- ✅ Hierarchical namespace enabled for big data analytics
- ✅ Soft delete and versioning for data protection
- ✅ Integration with Microsoft Fabric OneLake
- ✅ HIPAA-compliant lockdown (public access disabled when enabled)
- ✅ Lifecycle management policies
- ✅ Managed identity authentication

### Terraform Configuration

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

### Resource Naming Pattern

- Storage Account: `{prefix}{environment}sa` (e.g., `acmedevsa`)
- Containers: `bronze`, `silver`, `gold`

**Reference**: [Azure Data Lake Storage Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)

---

## 2. Microsoft Fabric

**Modules**: `modules/fabric_capacity`, `modules/fabric_workspace`, `modules/fabric_lakehouse`

### Overview

Microsoft Fabric provides a unified analytics platform integrating:
- **Capacity**: Compute resources (F-SKUs)
- **Workspace**: Collaboration and organization
- **Lakehouse**: Delta Lake-based storage with SQL query capabilities

### Supported SKUs

| SKU | Capacity Units (CU) | Recommended Use Case |
|-----|---------------------|----------------------|
| F2  | 2 CU | Development/Testing |
| F4  | 4 CU | Small workloads |
| F8  | 8 CU | Small production |
| F64 | 64 CU | Medium production |
| F128 | 128 CU | Large production |
| F256+ | 256+ CU | Enterprise scale |

### Configuration

```hcl
fabric_sku_name = "F64"  # Choose based on workload requirements

fabric_admin_object_ids = [
  "00000000-0000-0000-0000-000000000001"  # Service principal object ID
]

fabric_admin_upns = [
  "admin@yourcompany.com"
]
```

### Important Notes

⚠️ **Fabric API Limitations**:
- Does NOT support Azure AD **group** object IDs
- Only supports user or service principal object IDs
- Minimum one admin required for capacity creation

**Reference**: [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)

---

## 3. Azure Data Factory

**Module**: `modules/data_factory`

### Overview

Orchestrates data pipelines for ETL/ELT workloads, providing:
- Integration runtime for data movement
- Pipeline authoring and scheduling
- Git integration for version control
- Managed identity for authentication

### Key Features

- ✅ Integration with medallion storage layers
- ✅ Managed identity authentication (no keys!)
- ✅ Diagnostic logging to Log Analytics
- ✅ Git repository integration
- ✅ Trigger-based and scheduled pipelines

### Common Use Cases

- Ingest data from on-premises/cloud sources
- Transform Bronze → Silver → Gold
- Schedule batch processing jobs
- Trigger Microsoft Fabric notebook executions
- Data quality validation

### Terraform Configuration

```hcl
module "data_factory" {
  source = "../modules/data_factory"
  count  = var.enable_data_factory ? 1 : 0
  
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags
}
```

**Reference**: [Azure Data Factory](https://learn.microsoft.com/azure/data-factory/)

---

## 4. Azure Key Vault

**Module**: `modules/key_vault`

### Overview

Centralized secrets management service for:
- Connection strings and passwords
- API keys and tokens
- Certificates and keys
- Encryption keys for services

### Security Features

- ✅ Soft delete enabled (90-day recovery)
- ✅ Purge protection
- ✅ RBAC-based access control
- ✅ Managed identity integration
- ✅ Audit logging to Log Analytics
- ✅ Network isolation support

### Best Practices

**✅ DO:**
- Use managed identities to access secrets
- Reference secrets in Terraform via data sources
- Enable soft delete and purge protection
- Rotate secrets regularly
- Use RBAC, not access policies

**❌ DON'T:**
- Hardcode secrets in Terraform
- Use access keys when managed identity is available
- Share secrets across environments
- Disable auditing

### Terraform Example

```hcl
# Reference existing secret
data "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  key_vault_id = module.key_vault.id
}

# Use in resource
resource "azurerm_mssql_server" "example" {
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value
}
```

**Reference**: [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/)

---

## 5. Azure Purview (Optional)

**Module**: `modules/purview`

### Overview

Data governance and catalog service providing:
- Automated data discovery and classification
- Data lineage tracking
- Compliance reporting
- Integration with Azure data services

### When to Enable

✅ **Enable Purview if you need**:
- Data catalog for search and discovery
- Automated data classification (PII, PHI, etc.)
- Lineage tracking across data sources
- Compliance reporting (GDPR, HIPAA)

❌ **Skip Purview if**:
- Budget-constrained (Purview has additional costs)
- Simple data estate (< 5 data sources)
- Time-sensitive deployment (Purview takes 10-20 min to provision)

### Configuration

```hcl
enable_purview = true  # Set to false to skip

# Purview will automatically discover:
# - Storage accounts
# - Data Factory pipelines
# - SQL databases (if configured)
```

**Reference**: [Microsoft Purview](https://learn.microsoft.com/purview/)

---

## 6. Networking & Security

**Module**: `modules/networking`

### Overview

Enterprise-grade networking infrastructure:
- Virtual Network (VNet) with subnets
- Network Security Groups (NSGs)
- Service endpoints for Azure services
- Optional private endpoints

### Network Architecture

```
┌─────────────────────────────────────────┐
│          Virtual Network (VNet)         │
│                                         │
│  ┌─────────────┐  ┌─────────────────┐  │
│  │ Data Subnet │  │ Compute Subnet  │  │
│  │ (Storage,   │  │ (Data Factory,  │  │
│  │  Key Vault) │  │  VMs)           │  │
│  └─────────────┘  └─────────────────┘  │
│         ▲                  ▲            │
│         │   Service        │            │
│         │   Endpoints      │            │
└─────────┴──────────────────┴────────────┘
          │                  │
          ▼                  ▼
    Storage Account     Data Factory
```

### Security Features

- ✅ Network isolation for data services
- ✅ Deny public access by default (when HIPAA enabled)
- ✅ NSG flow logs to Log Analytics
- ✅ Service endpoints for Azure services
- ✅ DDoS protection (optional, additional cost)

### Configuration

```hcl
enable_networking = true

# Networking is automatically configured when enabled
# Subnets and NSGs are created based on enabled modules
```

**Reference**: [Azure Virtual Network](https://learn.microsoft.com/azure/virtual-network/)

---

## 7. Log Analytics

**Module**: `modules/log_analytics`

### Overview

Centralized logging and monitoring workspace for:
- Diagnostic logs from all Azure resources
- Azure Policy compliance tracking
- NSG flow logs
- Custom queries and alerts

### Features

- ✅ Retention period configurable (30-730 days)
- ✅ Integration with Azure Monitor
- ✅ KQL queries for log analysis
- ✅ Alerting and automation
- ✅ Compliance reporting

### Common Queries

**View all resource logs:**
```kql
AzureDiagnostics
| where TimeGenerated > ago(1h)
| summarize count() by ResourceType
```

**Policy compliance violations:**
```kql
AzurePolicyEvaluationDetails
| where ComplianceState == "NonCompliant"
| project ResourceId, PolicyDefinitionName, Reason
```

**Reference**: [Azure Log Analytics](https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-overview)

---

## Component Dependencies

Understanding component dependencies helps with troubleshooting and planning:

```
Resource Group (Required)
    │
    ├─> Networking (Optional)
    │       └─> Required by: Storage, Key Vault, Data Factory
    │
    ├─> Log Analytics (Optional)
    │       └─> Used by: All components for diagnostics
    │
    ├─> Storage (Medallion)
    │       └─> Dependency: Resource Group
    │       └─> Used by: Fabric, Data Factory
    │
    ├─> Key Vault
    │       └─> Dependency: Resource Group, Networking (optional)
    │
    ├─> Data Factory
    │       └─> Dependencies: Resource Group, Storage, Networking (optional)
    │
    ├─> Purview (Optional)
    │       └─> Dependencies: Resource Group, Storage
    │
    └─> Compliance Modules (HIPAA/GDPR)
            └─> Dependencies: Resource Group
            └─> Affects: All resources in scope
```

---

## Next Steps

- [Learn About Terraform Modules](Terraform-Modules-Reference)
- [Configure PowerShell Automation](PowerShell-Automation)
- [Enable Compliance Features](Compliance-and-Security)

---

[← Back to Home](Home)
