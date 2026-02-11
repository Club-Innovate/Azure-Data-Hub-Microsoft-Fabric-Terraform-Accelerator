# Azure Data Hub & Microsoft Fabric Terraform Accelerator - Wiki

Welcome to the comprehensive guide for the Azure Data Hub & Microsoft Fabric Terraform Accelerator! This wiki provides in-depth documentation, best practices, and advanced usage scenarios for deploying modern data analytics infrastructure on Azure.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. <a href="Getting-Started.md" target="_blank">Getting Started</a>
4. <a href="Core-Components.md" target="_blank">Core Components</a>
5. [Terraform Modules Reference](#terraform-modules-reference)
6. <a href="PowerShell-Automation.md" target="_blank">PowerShell Automation</a>
7. <a href="Compliance-and-Security.md" target="_blank">Compliance & Security</a>
8. <a href="Policy-as-Code-with-OPA.md" target="_blank">Policy-as-Code with OPA</a>
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Advanced Usage](#advanced-usage)
11. [Troubleshooting](#troubleshooting)
12. <a href="Best-Practices.md" target="_blank">Best Practices</a>
13. [Contributing](#contributing)
14. <a href="References.md" target="_blank">References</a>

---

## Introduction

### What is This Accelerator?

The **Azure Data Hub & Microsoft Fabric Terraform Accelerator** is a comprehensive Infrastructure-as-Code (IaC) solution that enables organizations to rapidly deploy and manage modern data analytics infrastructure on Azure.

### Key Features

- **Rapid Deployment**: Deploy complete data analytics infrastructure in minutes, not weeks
- **Fully Parameterized**: Multi-tenant ready with no hardcoded values
- **Compliance Automation**: Built-in HIPAA/HITECH and GDPR compliance enforcement
- **Policy-as-Code**: Automated governance with Open Policy Agent (OPA) and Conftest
- **Modular Architecture**: Choose only the components you need
- **Zero Licensing Cost**: Built entirely with free tools (Terraform, PowerShell, Azure CLI)
- **CI/CD Ready**: Includes Azure DevOps pipeline templates

### Target Audience

This accelerator is designed for:
- **Cloud Architects** designing data analytics platforms on Azure
- **DevOps Engineers** implementing Infrastructure-as-Code
- **Data Engineers** building medallion architecture data lakes
- **Compliance Officers** ensuring regulatory adherence
- **Organizations** seeking rapid, cost-effective Azure deployments

---

## Architecture Overview

### Solution Architecture

The accelerator implements a modern **Medallion Architecture** (Bronze/Silver/Gold) for data analytics, integrating Azure infrastructure services with Microsoft Fabric for unified analytics.

```
┌──────────────────────────────────────────────────────────────────┐
│                     Microsoft Fabric Layer                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │ Fabric Capacity  │  │ Fabric Workspace │  │  Lakehouses  │   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │ OneLake Integration
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Azure Infrastructure                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ ADLS Gen2    │  │ Data Factory │  │  Azure Purview       │   │
│  │ (Medallion)  │  │ (Pipelines)  │  │  (Governance)        │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Key Vault    │  │ API Mgmt     │  │  Log Analytics       │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Secure Networking
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Networking & Compliance                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Virtual Net  │  │ NSGs         │  │  Azure Policy        │   │
│  │ (VNet)       │  │ (Security)   │  │  (HIPAA/GDPR)        │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Design Patterns

#### 1. Medallion Architecture (Bronze/Silver/Gold)

The accelerator implements industry-standard **Medallion Architecture** for data lake organization:

- **Bronze Layer**: Raw data ingestion (minimal transformation)
- **Silver Layer**: Cleaned and validated data
- **Gold Layer**: Business-ready, aggregated datasets

This pattern aligns with Microsoft's data lakehouse best practices and is fully compatible with Microsoft Fabric OneLake.

#### 2. Infrastructure-as-Code (IaC) with Terraform

**HashiCorp Terraform** serves as the primary IaC tool, providing:
- **Declarative Configuration**: Define desired state, not procedural steps
- **State Management**: Track infrastructure changes over time
- **Provider Ecosystem**: Leverage 3000+ providers including Azure and Fabric
- **Modularity**: Reusable modules for consistent deployments

**Reference**: [HashiCorp Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

#### 3. Policy-as-Code with OPA

**Open Policy Agent (OPA)** and **Conftest** enforce governance policies at deployment time:
- Validate resource configurations before deployment
- Prevent security misconfigurations
- Enforce naming conventions and tagging standards
- Compliance validation (HIPAA, GDPR)

**Reference**: [Open Policy Agent Documentation](https://www.openpolicyagent.org/docs/latest/)

### Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **IaC Engine** | HashiCorp Terraform | Infrastructure provisioning |
| **Automation** | Microsoft PowerShell | Scripting, orchestration, compliance |
| **Cloud Platform** | Microsoft Azure | Infrastructure hosting |
| **Analytics Platform** | Microsoft Fabric | Unified analytics (OneLake, lakehouses) |
| **Policy Engine** | OPA + Conftest | Governance automation |
| **CI/CD** | Azure DevOps | Pipeline orchestration |
| **Version Control** | Git | Source control |

---

## Terraform Modules Reference

The accelerator is organized into reusable Terraform modules that can be deployed independently or as a complete solution.

### Module Directory Structure

```
terraform/
├── modules/
│   ├── networking/          # Virtual Networks, NSGs, Subnets
│   ├── storage/             # ADLS Gen2, Storage Accounts
│   ├── data-factory/        # Azure Data Factory, Pipelines
│   ├── key-vault/           # Azure Key Vault, Secrets
│   ├── purview/             # Azure Purview, Data Governance
│   ├── fabric-capacity/     # Microsoft Fabric Capacity
│   ├── fabric-workspace/    # Microsoft Fabric Workspaces
│   ├── api-management/      # Azure API Management
│   ├── monitoring/          # Log Analytics, Application Insights
│   └── compliance/          # Azure Policy, HIPAA/GDPR
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── main.tf
```

### Core Modules

#### 1. Networking Module (`modules/networking`)

**Purpose**: Provisions secure network infrastructure with private endpoints and network security groups.

**Key Resources**:
- Virtual Network (VNet)
- Subnets (data, compute, integration)
- Network Security Groups (NSGs)
- Private DNS Zones
- Private Endpoints

**Example Usage**:
```hcl
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = "vnet-datahub-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    data = {
      address_prefix = "10.0.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    compute = {
      address_prefix = "10.0.2.0/24"
    }
  }
  
  tags = var.common_tags
}
```

**Outputs**:
- `vnet_id`: Virtual Network resource ID
- `subnet_ids`: Map of subnet names to IDs
- `nsg_ids`: Network Security Group IDs

---

#### 2. Storage Module (`modules/storage`)

**Purpose**: Provisions ADLS Gen2 storage with medallion architecture (Bronze/Silver/Gold layers).

**Key Resources**:
- Storage Account (ADLS Gen2 enabled)
- Blob Containers (bronze, silver, gold)
- Hierarchical Namespace
- Lifecycle Management Policies
- Private Endpoints

**Example Usage**:
```hcl
module "storage" {
  source = "./modules/storage"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  storage_account_name = "stadlshub${var.environment}"
  
  medallion_layers = ["bronze", "silver", "gold"]
  
  lifecycle_rules = {
    archive_bronze = {
      days_after_creation = 90
      tier = "Archive"
    }
  }
  
  network_rules = {
    default_action = "Deny"
    virtual_network_subnet_ids = module.networking.subnet_ids["data"]
  }
  
  tags = var.common_tags
}
```

**Outputs**:
- `storage_account_id`: Storage Account resource ID
- `storage_account_name`: Storage Account name
- `container_names`: List of created containers
- `primary_endpoint`: Primary blob endpoint

---

#### 3. Data Factory Module (`modules/data-factory`)

**Purpose**: Provisions Azure Data Factory with linked services and integration runtimes.

**Key Resources**:
- Azure Data Factory instance
- Linked Services (ADLS, SQL, etc.)
- Integration Runtimes
- Managed Identity
- Private Endpoints

**Example Usage**:
```hcl
module "data_factory" {
  source = "./modules/data-factory"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  data_factory_name   = "adf-datahub-${var.environment}"
  
  linked_services = {
    adls = {
      type = "AzureBlobStorage"
      connection_string_secret = module.key_vault.secret_ids["adls-connection"]
    }
  }
  
  managed_identity_enabled = true
  
  tags = var.common_tags
}
```

**Outputs**:
- `data_factory_id`: Data Factory resource ID
- `data_factory_name`: Data Factory name
- `principal_id`: Managed Identity principal ID

---

#### 4. Key Vault Module (`modules/key-vault`)

**Purpose**: Provisions Azure Key Vault for secrets management with RBAC and private endpoints.

**Key Resources**:
- Azure Key Vault
- Secrets
- Access Policies / RBAC
- Private Endpoints
- Soft Delete & Purge Protection

**Example Usage**:
```hcl
module "key_vault" {
  source = "./modules/key-vault"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_name      = "kv-datahub-${var.environment}"
  
  sku_name = "standard"
  
  secrets = {
    adls-connection = {
      value = module.storage.primary_connection_string
    }
  }
  
  network_acls = {
    default_action = "Deny"
    virtual_network_subnet_ids = module.networking.subnet_ids["data"]
  }
  
  tags = var.common_tags
}
```

**Outputs**:
- `key_vault_id`: Key Vault resource ID
- `key_vault_uri`: Key Vault URI
- `secret_ids`: Map of secret names to IDs

---

#### 5. Fabric Capacity Module (`modules/fabric-capacity`)

**Purpose**: Provisions Microsoft Fabric capacity for analytics workloads.

**Key Resources**:
- Fabric Capacity (F-SKU)
- Capacity Administrators
- Auto-scaling configuration

**Example Usage**:
```hcl
module "fabric_capacity" {
  source = "./modules/fabric-capacity"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  capacity_name       = "fc-datahub-${var.environment}"
  
  sku = "F2"  # 2 vCores
  
  administrators = [
    "user@domain.com"
  ]
  
  tags = var.common_tags
}
```

**Outputs**:
- `capacity_id`: Fabric Capacity ID
- `capacity_name`: Capacity name

---

#### 6. Fabric Workspace Module (`modules/fabric-workspace`)

**Purpose**: Provisions Microsoft Fabric workspaces and lakehouses.

**Key Resources**:
- Fabric Workspace
- Lakehouses
- OneLake integration
- Workspace role assignments

**Example Usage**:
```hcl
module "fabric_workspace" {
  source = "./modules/fabric-workspace"
  
  workspace_name = "ws-datahub-${var.environment}"
  capacity_id    = module.fabric_capacity.capacity_id
  
  lakehouses = ["bronze", "silver", "gold"]
  
  workspace_admins = [
    "user@domain.com"
  ]
  
  tags = var.common_tags
}
```

**Outputs**:
- `workspace_id`: Workspace ID
- `lakehouse_ids`: Map of lakehouse names to IDs

---

#### 7. Monitoring Module (`modules/monitoring`)

**Purpose**: Provisions centralized monitoring and logging infrastructure.

**Key Resources**:
- Log Analytics Workspace
- Application Insights
- Diagnostic Settings
- Alerts and Action Groups

**Example Usage**:
```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  
  log_analytics_name = "log-datahub-${var.environment}"
  retention_days     = 90
  
  diagnostic_settings = {
    storage = {
      resource_id = module.storage.storage_account_id
      logs = ["StorageRead", "StorageWrite", "StorageDelete"]
      metrics = ["Transaction"]
    }
  }
  
  tags = var.common_tags
}
```

**Outputs**:
- `log_analytics_workspace_id`: Log Analytics workspace ID
- `application_insights_id`: Application Insights ID

---

#### 8. Compliance Module (`modules/compliance`)

**Purpose**: Provisions Azure Policy assignments for HIPAA/GDPR compliance.

**Key Resources**:
- Azure Policy Definitions
- Policy Assignments (HIPAA, GDPR)
- Policy Remediation Tasks

**Example Usage**:
```hcl
module "compliance" {
  source = "./modules/compliance"
  
  resource_group_name = var.resource_group_name
  
  compliance_frameworks = ["hipaa", "gdpr"]
  
  policy_assignments = {
    require_encryption = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/..."
      parameters = {
        effect = "Audit"
      }
    }
  }
  
  tags = var.common_tags
}
```

**Outputs**:
- `policy_assignment_ids`: Map of policy names to assignment IDs

---

### Module Development Guidelines

When creating new modules:

1. **Follow Standard Structure**:
   ```
   modules/<module-name>/
   ├── main.tf           # Primary resource definitions
   ├── variables.tf      # Input variables
   ├── outputs.tf        # Output values
   ├── versions.tf       # Provider version constraints
   └── README.md         # Module documentation
   ```

2. **Use Variable Validation**:
   ```hcl
   variable "environment" {
     type = string
     validation {
       condition     = contains(["dev", "staging", "prod"], var.environment)
       error_message = "Environment must be dev, staging, or prod."
     }
   }
   ```

3. **Implement Tagging Standards**:
   ```hcl
   locals {
     common_tags = merge(
       var.tags,
       {
         ManagedBy   = "Terraform"
         Environment = var.environment
       }
     )
   }
   ```

4. **Document All Variables and Outputs** in README.md

---

## CI/CD Pipeline

The accelerator includes comprehensive Azure DevOps pipeline templates for automated deployment and governance.

### Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Validation                                         │
│ ├── Terraform Format Check (terraform fmt)                 │
│ ├── Terraform Validate                                     │
│ ├── Policy Validation (Conftest/OPA)                       │
│ └── Security Scan (Checkov/TFSec)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: Plan                                               │
│ ├── Terraform Init                                         │
│ ├── Terraform Plan                                         │
│ ├── Cost Estimation (Infracost)                            │
│ └── Publish Plan Artifact                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: Manual Approval (Production Only)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 4: Deploy                                             │
│ ├── Terraform Apply                                        │
│ ├── Post-Deployment Validation                             │
│ └── Smoke Tests                                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 5: Compliance Validation                              │
│ ├── Azure Policy Compliance Scan                           │
│ ├── Security Posture Assessment                            │
│ └── Compliance Report Generation                           │
└─────────────────────────────────────────────────────────────┘
```

### Azure DevOps Pipeline Configuration

**File**: `azure-pipelines.yml`

```yaml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - terraform/**
      - pipelines/**

variables:
  - group: terraform-variables
  - name: tfVersion
    value: '1.6.0'
  - name: terraformWorkingDirectory
    value: '$(System.DefaultWorkingDirectory)/terraform'

stages:
  # ============================================
  # Stage 1: Validation
  # ============================================
  - stage: Validate
    displayName: 'Validation & Security Checks'
    jobs:
      - job: TerraformValidation
        displayName: 'Terraform Validation'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(tfVersion)
          
          - task: TerraformCLI@0
            displayName: 'Terraform Format Check'
            inputs:
              command: 'fmt'
              workingDirectory: $(terraformWorkingDirectory)
              commandOptions: '-check -recursive'
          
          - task: TerraformCLI@0
            displayName: 'Terraform Init'
            inputs:
              command: 'init'
              workingDirectory: $(terraformWorkingDirectory)
              backendType: 'azurerm'
              backendServiceArm: $(serviceConnection)
          
          - task: TerraformCLI@0
            displayName: 'Terraform Validate'
            inputs:
              command: 'validate'
              workingDirectory: $(terraformWorkingDirectory)
      
      - job: PolicyValidation
        displayName: 'Policy Validation (OPA/Conftest)'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - script: |
              # Install Conftest
              wget https://github.com/open-policy-agent/conftest/releases/download/v0.45.0/conftest_0.45.0_Linux_x86_64.tar.gz
              tar xzf conftest_0.45.0_Linux_x86_64.tar.gz
              sudo mv conftest /usr/local/bin/
            displayName: 'Install Conftest'
          
          - task: TerraformCLI@0
            displayName: 'Generate Terraform Plan JSON'
            inputs:
              command: 'plan'
              workingDirectory: $(terraformWorkingDirectory)
              commandOptions: '-out=tfplan'
          
          - script: |
              terraform show -json tfplan > tfplan.json
            displayName: 'Convert Plan to JSON'
            workingDirectory: $(terraformWorkingDirectory)
          
          - script: |
              conftest test tfplan.json -p $(System.DefaultWorkingDirectory)/policies
            displayName: 'Run Policy Tests'
            workingDirectory: $(terraformWorkingDirectory)
      
      - job: SecurityScan
        displayName: 'Security Scanning'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - script: |
              pip install checkov
              checkov -d $(terraformWorkingDirectory) --framework terraform --output junitxml > $(Build.ArtifactStagingDirectory)/checkov-report.xml
            displayName: 'Run Checkov Security Scan'
          
          - task: PublishTestResults@2
            displayName: 'Publish Security Scan Results'
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: '$(Build.ArtifactStagingDirectory)/checkov-report.xml'
              testRunTitle: 'Checkov Security Scan'

  # ============================================
  # Stage 2: Plan (Development)
  # ============================================
  - stage: PlanDev
    displayName: 'Plan - Development'
    dependsOn: Validate
    condition: succeeded()
    variables:
      - name: environment
        value: 'dev'
    jobs:
      - job: TerraformPlan
        displayName: 'Terraform Plan'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: $(tfVersion)
          
          - task: TerraformCLI@0
            displayName: 'Terraform Init'
            inputs:
              command: 'init'
              workingDirectory: '$(terraformWorkingDirectory)/environments/$(environment)'
              backendType: 'azurerm'
              backendServiceArm: $(serviceConnection)
              backendAzureRmResourceGroupName: 'rg-terraform-state'
              backendAzureRmStorageAccountName: 'sttfstate$(environment)'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'datahub.$(environment).tfstate'
          
          - task: TerraformCLI@0
            displayName: 'Terraform Plan'
            inputs:
              command: 'plan'
              workingDirectory: '$(terraformWorkingDirectory)/environments/$(environment)'
              commandOptions: '-out=tfplan -var-file="terraform.tfvars"'
              environmentServiceName: $(serviceConnection)
          
          - task: PublishPipelineArtifact@1
            displayName: 'Publish Plan Artifact'
            inputs:
              targetPath: '$(terraformWorkingDirectory)/environments/$(environment)/tfplan'
              artifact: 'tfplan-$(environment)'

  # ============================================
  # Stage 3: Deploy (Development)
  # ============================================
  - stage: DeployDev
    displayName: 'Deploy - Development'
    dependsOn: PlanDev
    condition: succeeded()
    variables:
      - name: environment
        value: 'dev'
    jobs:
      - deployment: TerraformApply
        displayName: 'Terraform Apply'
        environment: 'development'
        pool:
          vmImage: 'ubuntu-latest'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadPipelineArtifact@2
                  inputs:
                    artifact: 'tfplan-$(environment)'
                    path: '$(Pipeline.Workspace)/tfplan'
                
                - task: TerraformInstaller@0
                  inputs:
                    terraformVersion: $(tfVersion)
                
                - task: TerraformCLI@0
                  displayName: 'Terraform Apply'
                  inputs:
                    command: 'apply'
                    workingDirectory: '$(terraformWorkingDirectory)/environments/$(environment)'
                    commandOptions: '$(Pipeline.Workspace)/tfplan/tfplan'
                    environmentServiceName: $(serviceConnection)
                
                - script: |
                    # Post-deployment validation
                    echo "Running smoke tests..."
                    # Add smoke test scripts here
                  displayName: 'Post-Deployment Validation'

  # ============================================
  # Stage 4: Plan & Deploy (Production)
  # ============================================
  - stage: PlanProd
    displayName: 'Plan - Production'
    dependsOn: DeployDev
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    variables:
      - name: environment
        value: 'prod'
    jobs:
      - job: TerraformPlan
        displayName: 'Terraform Plan'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: $(tfVersion)
          
          - task: TerraformCLI@0
            displayName: 'Terraform Init'
            inputs:
              command: 'init'
              workingDirectory: '$(terraformWorkingDirectory)/environments/$(environment)'
              backendType: 'azurerm'
              backendServiceArm: $(serviceConnection)
              backendAzureRmResourceGroupName: 'rg-terraform-state'
              backendAzureRmStorageAccountName: 'sttfstate$(environment)'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'datahub.$(environment).tfstate'
          
          - task: TerraformCLI@0
            displayName: 'Terraform Plan'
            inputs:
              command: 'plan'
              workingDirectory: '$(terraformWorkingDirectory)/environments/$(environment)'
              commandOptions: '-out=tfplan -var-file="terraform.tfvars"'
              environmentServiceName: $(serviceConnection)
          
          - task: PublishPipelineArtifact@1
            inputs:
              targetPath: '$(terraformWorkingDirectory)/environments/$(environment)/tfplan'
              artifact: 'tfplan-$(environment)'

  - stage: DeployProd
    displayName: 'Deploy - Production'
    dependsOn: PlanProd
    condition: succeeded()
    variables:
      - name: environment
        value: 'prod'
    jobs:
      - deployment: TerraformApply
        displayName: 'Terraform Apply'
        environment: 'production'  # Requires manual approval
        pool:
          vmImage: 'ubuntu-latest'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadPipelineArtifact@2
                  inputs:
                    artifact: 'tfplan-$(environment)'
                    path: '$(Pipeline.Workspace)/tfplan'
                
                - task: TerraformInstaller@0
                  inputs:
                    terraformVersion: $(tfVersion)
                
                - task: TerraformCLI@0
                  displayName: 'Terraform Apply'
                  inputs:
                    command: 'apply'
                    workingDirectory: '$(terraformWorkingDirectory)/environments/$(environment)'
                    commandOptions: '$(Pipeline.Workspace)/tfplan/tfplan'
                    environmentServiceName: $(serviceConnection)

  # ============================================
  # Stage 5: Compliance Validation
  # ============================================
  - stage: ComplianceValidation
    displayName: 'Compliance Validation'
    dependsOn: DeployProd
    condition: succeeded()
    jobs:
      - job: AzurePolicyCompliance
        displayName: 'Azure Policy Compliance Check'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: AzureCLI@2
            displayName: 'Check Policy Compliance'
            inputs:
              azureSubscription: $(serviceConnection)
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Get compliance state
                az policy state summarize \
                  --resource-group rg-datahub-prod \
                  --query 'results[0].{Compliant:resourceDetails.complianceState}' \
                  -o table
          
          - script: |
              # Generate compliance report
              pwsh -File $(System.DefaultWorkingDirectory)/scripts/Generate-ComplianceReport.ps1 \
                -Environment prod \
                -OutputPath $(Build.ArtifactStagingDirectory)/compliance-report.html
            displayName: 'Generate Compliance Report'
          
          - task: PublishPipelineArtifact@1
            inputs:
              targetPath: '$(Build.ArtifactStagingDirectory)/compliance-report.html'
              artifact: 'compliance-report'
```

### Pipeline Setup Instructions

#### Prerequisites

1. **Azure DevOps Organization** with appropriate permissions
2. **Azure Service Connection** configured in Azure DevOps
3. **Terraform State Storage Account** in Azure

#### Step 1: Configure Service Connection

1. Navigate to **Project Settings** > **Service connections**
2. Create **New service connection** > **Azure Resource Manager**
3. Select **Service principal (automatic)**
4. Configure:
   - Subscription: Your Azure subscription
   - Resource group: Leave empty for subscription-level access
   - Service connection name: `azure-terraform-connection`
5. Click **Save**

#### Step 2: Create Variable Group

1. Navigate to **Pipelines** > **Library** > **+ Variable group**
2. Name: `terraform-variables`
3. Add variables:
   ```
   serviceConnection: azure-terraform-connection
   azureSubscriptionId: <your-subscription-id>
   tenantId: <your-tenant-id>
   ```
4. Click **Save**

#### Step 3: Configure Environments

1. Navigate to **Pipelines** > **Environments**
2. Create environments:
   - `development` (no approvals)
   - `production` (with approvals)
3. For **production** environment:
   - Click **...** > **Approvals and checks**
   - Add **Approvals** check
   - Add approvers (e.g., Cloud Architect, DevOps Lead)

#### Step 4: Initialize Terraform State Storage

Run this script to create Azure backend storage:

```bash
#!/bin/bash
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="sttfstatedev"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT
```

#### Step 5: Commit Pipeline Configuration

1. Add `azure-pipelines.yml` to repository root
2. Commit and push:
   ```bash
   git add azure-pipelines.yml
   git commit -m "Add CI/CD pipeline configuration"
   git push origin main
   ```

#### Step 6: Create Pipeline in Azure DevOps

1. Navigate to **Pipelines** > **New pipeline**
2. Select **Azure Repos Git** (or your Git provider)
3. Select your repository
4. Select **Existing Azure Pipelines YAML file**
5. Path: `/azure-pipelines.yml`
6. Click **Continue** > **Run**

### Pipeline Features

#### 1. **Multi-Environment Support**
- Separate stages for Development, Staging, Production
- Environment-specific variable files
- Isolated Terraform state per environment

#### 2. **Security & Compliance Gates**
- **Conftest/OPA**: Policy-as-Code validation
- **Checkov**: Infrastructure security scanning
- **Azure Policy**: Post-deployment compliance checks

#### 3. **Cost Estimation**
To enable Infracost integration:

```yaml
- script: |
    # Install Infracost
    curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
    
    # Generate cost estimate
    infracost breakdown \
      --path $(terraformWorkingDirectory) \
      --format json \
      --out-file $(Build.ArtifactStagingDirectory)/infracost.json
  displayName: 'Generate Cost Estimate'
  env:
    INFRACOST_API_KEY: $(infracostApiKey)
```

#### 4. **Automated Rollback**
Add rollback capability:

```yaml
- task: TerraformCLI@0
  displayName: 'Rollback on Failure'
  condition: failed()
  inputs:
    command: 'apply'
    workingDirectory: $(terraformWorkingDirectory)
    commandOptions: '-destroy -auto-approve'
```

### Troubleshooting Pipeline Issues

| Issue | Solution |
|-------|----------|
| **Authentication failures** | Verify service connection has Contributor role on subscription |
| **State lock errors** | Manually release lock: `terraform force-unlock <LOCK_ID>` |
| **Plan timeouts** | Increase timeout in pipeline YAML: `timeoutInMinutes: 60` |
| **Module not found** | Ensure `terraform init` runs before plan/apply |

---

## Advanced Usage

### Multi-Region Deployment

Deploy infrastructure across multiple Azure regions for high availability:

```hcl
# main.tf
locals {
  regions = ["eastus", "westus", "northeurope"]
}

module "regional_hub" {
  source   = "./modules/regional-hub"
  for_each = toset(local.regions)
  
  location            = each.value
  resource_group_name = "rg-datahub-${each.value}-${var.environment}"
  
  # Shared resources
  global_key_vault_id = module.global_key_vault.key_vault_id
  
  tags = merge(var.common_tags, {
    Region = each.value
  })
}

# Configure geo-replication for storage
resource "azurerm_storage_account_customer_managed_key" "geo_replication" {
  for_each = module.regional_hub
  
  storage_account_id = each.value.storage_account_id
  
  # GRS (Geo-Redundant Storage)
  account_replication_type = "GRS"
}
```

### Multi-Tenant Architecture

Support multiple tenants with isolated resources:

```hcl
# tenants.tf
variable "tenants" {
  type = map(object({
    name          = string
    capacity_sku  = string
    admin_emails  = list(string)
  }))
  
  default = {
    contoso = {
      name         = "contoso"
      capacity_sku = "F2"
      admin_emails = ["admin@contoso.com"]
    }
    fabrikam = {
      name         = "fabrikam"
      capacity_sku = "F4"
      admin_emails = ["admin@fabrikam.com"]
    }
  }
}

module "tenant_infrastructure" {
  source   = "./modules/tenant-hub"
  for_each = var.tenants
  
  tenant_name      = each.value.name
  capacity_sku     = each.value.capacity_sku
  admin_emails     = each.value.admin_emails
  
  # Tenant-specific resource group
  resource_group_name = "rg-datahub-${each.value.name}-${var.environment}"
  
  # Shared networking (optional)
  shared_vnet_id = module.shared_networking.vnet_id
  
  tags = merge(var.common_tags, {
    Tenant = each.value.name
  })
}
```

### Disaster Recovery Configuration

Implement automated disaster recovery with Azure Site Recovery:

```hcl
# disaster-recovery.tf
module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  
  primary_region   = "eastus"
  secondary_region = "westus"
  
  # Resources to replicate
  protected_resources = {
    storage = module.storage.storage_account_id
    adf     = module.data_factory.data_factory_id
  }
  
  # Recovery objectives
  rpo_minutes = 15  # Recovery Point Objective
  rto_minutes = 60  # Recovery Time Objective
  
  # Automated failover configuration
  automated_failover = {
    enabled   = true
    threshold = "Critical"  # Trigger on critical health status
  }
  
  tags = var.common_tags
}

# Backup configuration
resource "azurerm_backup_policy_vm" "daily" {
  name                = "backup-policy-daily"
  resource_group_name = var.resource_group_name
  recovery_vault_name = module.disaster_recovery.vault_name
  
  backup = {
    frequency = "Daily"
    time      = "23:00"
  }
  
  retention_daily = {
    count = 30
  }
  
  retention_weekly = {
    count    = 12
    weekdays = ["Sunday"]
  }
}
```

### Custom Module Development

Create reusable modules for organization-specific requirements:

**Example**: Custom Data Lakehouse Module

```hcl
# modules/custom-lakehouse/main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 0.1"
    }
  }
}

# Storage with custom medallion structure
module "storage" {
  source = "../storage"
  
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_name = var.storage_account_name
  
  # Custom layer structure
  medallion_layers = concat(
    var.standard_layers,  # bronze, silver, gold
    var.custom_layers     # e.g., platinum, archive
  )
  
  # Lifecycle rules per layer
  lifecycle_rules = {
    for layer in var.custom_layers : layer => {
      days_after_creation = lookup(var.retention_days, layer, 90)
      tier                = lookup(var.tier_mapping, layer, "Cool")
    }
  }
}

# Fabric workspace with custom configuration
resource "fabric_workspace" "custom" {
  name        = var.workspace_name
  capacity_id = var.capacity_id
  
  # Custom workspace settings
  settings = {
    data_model_default_storage_format = "Delta"
    spark_compute_default_pool_size   = var.spark_pool_size
  }
}

# Data Factory pipelines for custom ETL
resource "azurerm_data_factory_pipeline" "custom_etl" {
  for_each = var.custom_pipelines
  
  name                = each.key
  data_factory_id     = module.data_factory.data_factory_id
  
  activities_json = file("${path.module}/pipelines/${each.value.template}")
  
  parameters = merge(
    each.value.parameters,
    {
      storage_account_name = module.storage.storage_account_name
      workspace_id         = fabric_workspace.custom.id
    }
  )
}
```

**Usage**:

```hcl
module "custom_lakehouse" {
  source = "./modules/custom-lakehouse"
  
  resource_group_name  = "rg-custom-lakehouse"
  location             = "eastus"
  storage_account_name = "stcustomlakehouse"
  workspace_name       = "ws-custom-lakehouse"
  capacity_id          = module.fabric_capacity.capacity_id
  
  # Standard medallion layers
  standard_layers = ["bronze", "silver", "gold"]
  
  # Custom layers for specialized use cases
  custom_layers = ["platinum", "archive", "sandbox"]
  
  # Retention policy per layer
  retention_days = {
    bronze   = 30
    silver   = 90
    gold     = 365
    platinum = 1825  # 5 years
    archive  = 2555  # 7 years (compliance)
    sandbox  = 7     # Temporary experimentation
  }
  
  # Custom ETL pipelines
  custom_pipelines = {
    platinum_aggregation = {
      template   = "platinum-aggregation.json"
      parameters = {
        aggregation_interval = "hourly"
      }
    }
  }
  
  spark_pool_size = "Medium"
  
  tags = var.common_tags
}
```

### Dynamic Configuration with Workspaces

Use Terraform workspaces for environment management:

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch to workspace
terraform workspace select dev

# Deploy with workspace-specific variables
terraform apply -var-file="env/${terraform.workspace}.tfvars"
```

**Workspace-specific configuration**:

```hcl
# main.tf
locals {
  workspace_config = {
    dev = {
      capacity_sku     = "F2"
      enable_dr        = false
      backup_retention = 7
    }
    staging = {
      capacity_sku     = "F4"
      enable_dr        = true
      backup_retention = 30
    }
    prod = {
      capacity_sku     = "F64"
      enable_dr        = true
      backup_retention = 365
    }
  }
  
  current_config = local.workspace_config[terraform.workspace]
}

module "fabric_capacity" {
  source = "./modules/fabric-capacity"
  
  capacity_sku = local.current_config.capacity_sku
  # ... other configuration
}
```

### Secrets Management Integration

Integrate with external secrets managers:

```hcl
# secrets.tf
data "azurerm_key_vault" "shared" {
  name                = "kv-shared-secrets"
  resource_group_name = "rg-shared-infra"
}

data "azurerm_key_vault_secret" "fabric_api_key" {
  name         = "fabric-api-key"
  key_vault_id = data.azurerm_key_vault.shared.id
}

# Use secrets in resources
resource "fabric_workspace" "secured" {
  name        = "ws-secured"
  capacity_id = var.capacity_id
  
  # Authenticate with secret
  api_key = data.azurerm_key_vault_secret.fabric_api_key.value
}

# Store generated secrets back to Key Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "adls-connection-string-${var.environment}"
  value        = module.storage.primary_connection_string
  key_vault_id = data.azurerm_key_vault.shared.id
  
  lifecycle {
    ignore_changes = [value]  # Prevent updates on every run
  }
}
```

### Performance Optimization

#### 1. **Parallel Resource Creation**

Terraform automatically parallelizes resource creation, but you can optimize dependencies:

```hcl
# Allow parallel creation of independent resources
resource "azurerm_storage_account" "bronze" {
  # Independent resource - can be created in parallel
}

resource "azurerm_storage_account" "silver" {
  # Independent resource - can be created in parallel
}

# Explicit dependency only when needed
resource "azurerm_storage_container" "bronze_container" {
  storage_account_name = azurerm_storage_account.bronze.name
  # Implicit dependency - Terraform handles ordering
}
```

#### 2. **State File Optimization**

For large deployments, split state files:

```hcl
# backend-networking.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "networking.tfstate"  # Separate state file
  }
}

# backend-compute.tf (in different directory)
terraform {
  backend "azurerm" {
    key = "compute.tfstate"  # Separate state file
  }
}
```

#### 3. **Resource Targeting**

Apply changes to specific resources:

```bash
# Apply only networking changes
terraform apply -target=module.networking

# Apply only storage changes
terraform apply -target=module.storage
```

---

## Troubleshooting

### Common Issues and Resolutions

#### 1. **Terraform State Lock Issues**

**Symptom**: "Error: Error acquiring the state lock"

**Cause**: Previous Terraform operation was interrupted, leaving state file locked.

**Resolution**:
```bash
# List current locks
terraform force-unlock <LOCK_ID>

# If using Azure backend, check blob lease
az storage blob lease break \
  --container-name tfstate \
  --blob-name terraform.tfstate \
  --account-name sttfstate
```

**Prevention**:
- Always use `Ctrl+C` gracefully to interrupt Terraform
- Configure automatic lock timeout in backend:
  ```hcl
  terraform {
    backend "azurerm" {
      # ... other config
      lease_duration = "60"  # seconds
    }
  }
  ```

---

#### 2. **Provider Authentication Failures**

**Symptom**: "Error: building account: could not acquire access token"

**Cause**: Expired Azure CLI session or misconfigured service principal.

**Resolution**:

**Option A**: Re-authenticate Azure CLI
```bash
az login
az account set --subscription "<subscription-id>"
```

**Option B**: Use environment variables
```bash
export ARM_CLIENT_ID="<service-principal-app-id>"
export ARM_CLIENT_SECRET="<service-principal-password>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

**Option C**: Configure provider in Terraform
```hcl
provider "azurerm" {
  features {}
  
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

---

#### 3. **Resource Already Exists Errors**

**Symptom**: "Error: A resource with the ID already exists"

**Cause**: Resource exists in Azure but not in Terraform state.

**Resolution**:

**Import existing resource**:
```bash
# Find resource ID
az resource show \
  --name "my-storage-account" \
  --resource-group "rg-datahub" \
  --resource-type "Microsoft.Storage/storageAccounts" \
  --query id -o tsv

# Import into Terraform state
terraform import azurerm_storage_account.example /subscriptions/.../resourceGroups/.../providers/Microsoft.Storage/storageAccounts/myaccount
```

**Alternative**: Remove resource from Azure and let Terraform recreate:
```bash
az resource delete --ids <resource-id>
terraform apply
```

---

#### 4. **Module Not Found Errors**

**Symptom**: "Error: Module not installed"

**Cause**: Modules haven't been downloaded or path is incorrect.

**Resolution**:
```bash
# Re-initialize Terraform to download modules
terraform init -upgrade

# Verify module paths
terraform get

# For local modules, check path syntax
module "example" {
  source = "./modules/example"  # Relative path
  # source = "../shared/modules/example"  # Parent directory
}
```

---

#### 5. **Insufficient Permissions**

**Symptom**: "Error: authorization failed" or "does not have permission to perform action"

**Cause**: Service principal or user lacks required Azure RBAC roles.

**Resolution**:

**Check current permissions**:
```bash
az role assignment list --assignee <service-principal-id> --output table
```

**Grant required roles**:
```bash
# Contributor role (for resource management)
az role assignment create \
  --assignee <service-principal-id> \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>"

# User Access Administrator (for role assignments)
az role assignment create \
  --assignee <service-principal-id> \
  --role "User Access Administrator" \
  --scope "/subscriptions/<subscription-id>"
```

**Minimum required roles**:
- **Contributor**: Create/modify/delete resources
- **User Access Administrator**: Assign roles (for Key Vault, RBAC)
- **Storage Blob Data Contributor**: Access storage account data

---

#### 6. **Microsoft Fabric API Errors**

**Symptom**: "Error: Failed to create Fabric workspace" or "API returned 401 Unauthorized"

**Cause**: Missing or expired Fabric API credentials.

**Resolution**:

**Verify Fabric permissions**:
```powershell
# Check Fabric admin permissions
Get-FabricCapacity | Where-Object {$_.Admins -contains "user@domain.com"}
```

**Generate new API token**:
```powershell
# Authenticate to Fabric
Connect-Fabric -TenantId "<tenant-id>"

# Generate service principal for Fabric
$sp = New-FabricServicePrincipal -DisplayName "Terraform-Fabric-SP"

# Store credentials in Key Vault
az keyvault secret set \
  --vault-name "kv-terraform-secrets" \
  --name "fabric-api-key" \
  --value $sp.ClientSecret
```

**Configure Terraform provider**:
```hcl
provider "fabric" {
  tenant_id     = var.tenant_id
  client_id     = var.fabric_client_id
  client_secret = data.azurerm_key_vault_secret.fabric_api_key.value
}
```

---

#### 7. **Resource Naming Conflicts**

**Symptom**: "Error: Name is already taken" (for globally unique names)

**Cause**: Storage account names, Key Vault names must be globally unique.

**Resolution**:

**Use unique naming convention**:
```hcl
locals {
  unique_suffix = substr(sha256(var.subscription_id), 0, 8)
}

resource "azurerm_storage_account" "example" {
  name = "st${var.project}${var.environment}${local.unique_suffix}"
  # Guaranteed unique: "stdatahubdev3f7a9b12"
}
```

**Validate naming before apply**:
```bash
# Check name availability
az storage account check-name \
  --name "stdatahubdev" \
  --query nameAvailable -o tsv
```

---

#### 8. **Policy Validation Failures (OPA/Conftest)**

**Symptom**: "FAIL - policy/naming.rego: Resource name does not match convention"

**Cause**: Resources don't comply with organizational policies.

**Resolution**:

**Review policy violation**:
```bash
conftest test tfplan.json -p policies --output table
```

**Fix resource naming**:
```hcl
# Before (non-compliant)
resource "azurerm_resource_group" "example" {
  name = "my-rg"  # Fails naming policy
}

# After (compliant)
resource "azurerm_resource_group" "example" {
  name = "rg-${var.project}-${var.environment}-${var.location}"
  # Produces: "rg-datahub-dev-eastus"
}
```

**Temporarily bypass policies** (for testing):
```bash
# Skip policy validation
terraform apply -var="skip_policy_validation=true"
```

---

#### 9. **Timeout Errors During Deployment**

**Symptom**: "Error: context deadline exceeded" or "timeout while waiting for state"

**Cause**: Resource provisioning takes longer than default timeout.

**Resolution**:

**Increase timeout in resource definition**:
```hcl
resource "azurerm_virtual_network" "example" {
  # ... configuration
  
  timeouts {
    create = "60m"  # Increase from default 30m
    update = "60m"
    delete = "60m"
  }
}
```

**For module timeouts**:
```hcl
module "fabric_capacity" {
  source = "./modules/fabric-capacity"
  
  # ... configuration
  
  timeouts = {
    create = "90m"  # Large capacity provisioning
  }
}
```

---

#### 10. **Dependency Resolution Errors**

**Symptom**: "Error: reference to undeclared resource"

**Cause**: Implicit dependency not detected by Terraform.

**Resolution**:

**Use explicit `depends_on`**:
```hcl
resource "azurerm_storage_container" "bronze" {
  # ... configuration
  
  # Explicit dependency
  depends_on = [
    azurerm_role_assignment.storage_contributor
  ]
}
```

**Reference output values to create implicit dependencies**:
```hcl
resource "azurerm_data_factory_linked_service" "adls" {
  # Implicit dependency through reference
  connection_string = module.storage.primary_connection_string
}
```

---

### Debugging Techniques

#### Enable Terraform Debug Logging

```bash
# Set debug level
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# Run Terraform command
terraform apply

# Review logs
cat terraform-debug.log | grep ERROR
```

**Log Levels**: TRACE, DEBUG, INFO, WARN, ERROR

#### Validate Configuration Before Apply

```bash
# Validate syntax
terraform validate

# Check formatting
terraform fmt -check -recursive

# Generate plan without applying
terraform plan -out=tfplan

# Review plan in detail
terraform show tfplan
```

#### Use Terraform Console for Testing

```bash
# Start interactive console
terraform console

# Test expressions
> module.storage.storage_account_name
"stadlshubdev"

> local.common_tags
{
  "Environment" = "dev"
  "ManagedBy" = "Terraform"
}
```

---

### Performance Troubleshooting

#### Slow Terraform Plans

**Symptom**: `terraform plan` takes several minutes to complete.

**Diagnosis**:
```bash
# Profile Terraform execution
export TF_LOG=TRACE
terraform plan 2>&1 | grep -i "elapsed time"
```

**Solutions**:
1. **Reduce resource count**: Split large deployments into modules
2. **Optimize state file**: Use partial refresh
   ```bash
   terraform plan -refresh=false
   ```
3. **Parallelize**: Increase parallelism (default 10)
   ```bash
   terraform apply -parallelism=20
   ```

#### Azure API Rate Limiting

**Symptom**: "Too many requests" errors during deployment.

**Solutions**:
- Add delays between resource creation:
  ```hcl
  resource "time_sleep" "wait_30_seconds" {
    create_duration = "30s"
  }
  
  resource "azurerm_resource_group" "example" {
    depends_on = [time_sleep.wait_30_seconds]
  }
  ```
- Reduce parallelism:
  ```bash
  terraform apply -parallelism=5
  ```

---

### Getting Help

If issues persist:

1. **Review Terraform Logs**: Set `TF_LOG=DEBUG` for detailed output
2. **Check Azure Activity Logs**: Review failed operations in Azure Portal
3. **Consult Documentation**:
   - [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
   - [Microsoft Fabric Terraform Provider](https://registry.terraform.io/providers/microsoft/fabric/latest/docs)
4. **Open GitHub Issue**: Include:
   - Terraform version (`terraform version`)
   - Provider versions
   - Redacted debug logs
   - Steps to reproduce

---

## Contributing

We welcome contributions from the community! This section provides guidelines for contributing to the Azure Data Hub & Microsoft Fabric Terraform Accelerator.

### How to Contribute

#### Types of Contributions

- **Bug Reports**: Identify and report issues
- **Feature Requests**: Suggest new capabilities
- **Code Contributions**: Submit bug fixes or new modules
- **Documentation**: Improve wiki, READMEs, code comments
- **Policy Enhancements**: Add OPA/Conftest policies
- **CI/CD Improvements**: Enhance pipeline templates

---

### Getting Started

#### 1. Fork the Repository

```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/<your-username>/Azure-Data-Hub-Microsoft-Fabric-Terraform-Accelerator.git
cd Azure-Data-Hub-Microsoft-Fabric-Terraform-Accelerator

# Add upstream remote
git remote add upstream https://github.com/Club-Innovate/Azure-Data-Hub-Microsoft-Fabric-Terraform-Accelerator.git
```

#### 2. Create a Feature Branch

```bash
# Create branch from main
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-number-description
```

**Branch Naming Convention**:
- Features: `feature/<descriptive-name>`
- Bug fixes: `fix/<issue-number>-<short-description>`
- Documentation: `docs/<topic>`
- Policies: `policy/<policy-name>`

#### 3. Make Your Changes

**Code Guidelines**:
- Follow [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use consistent formatting: `terraform fmt -recursive`
- Validate configuration: `terraform validate`
- Run policy tests: `conftest test`
- Add comments for complex logic
- Update relevant documentation

**Commit Message Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Examples**:
```bash
git commit -m "feat(storage): add lifecycle management for archive tier

- Implement automated archival for bronze layer after 90 days
- Add configurable retention policies per medallion layer
- Include Conftest policy to enforce archival standards

Closes #42"
```

**Commit Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

#### 4. Test Your Changes

**Local Testing**:
```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Run policy tests
conftest test --policy policies/ terraform/

# Test deployment in dev environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve
```

**Integration Testing**:
- Deploy to isolated test subscription/resource group
- Verify all resources provision successfully
- Test compliance policies trigger correctly
- Validate CI/CD pipeline runs without errors

#### 5. Submit Pull Request

```bash
# Push branch to your fork
git push origin feature/your-feature-name
```

**Pull Request Guidelines**:
1. Navigate to original repository on GitHub
2. Click **New Pull Request**
3. Select your branch from your fork
4. Fill out PR template:
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Policy enhancement
   
   ## Testing
   - [ ] Terraform validate passed
   - [ ] Policy tests passed
   - [ ] Deployed to test environment
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Documentation updated
   - [ ] Tests added/updated
   - [ ] No breaking changes (or documented)
   
   ## Related Issues
   Closes #<issue-number>
   ```

5. Request review from maintainers
6. Address review feedback
7. Once approved, maintainers will merge

---

### Development Setup

#### Prerequisites

**Required Tools**:
- [Terraform](https://www.terraform.io/downloads) >= 1.6.0
- [Azure CLI
