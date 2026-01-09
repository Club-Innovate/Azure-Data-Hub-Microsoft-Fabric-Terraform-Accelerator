# Azure Data Hub & Microsoft Fabric Terraform Accelerator

## What's New

### HIPAA & GDPR Compliance Automation
- **Enable HIPAA/HITECH and GDPR compliance** with a single variable in your `terraform.tfvars`.
- Automatically assigns built-in Azure Policy initiatives for HIPAA and GDPR at the resource group or resource level.
- Diagnostic settings, network restrictions, and managed identity for remediation are all handled for you.
- Post-deployment PowerShell script automates storage lockdown for HIPAA.
- Validate compliance with the included PowerShell script for instant feedback.
- **Compliance automation is a starting point:** Review assigned policies in the Azure Portal and use the validation script to identify additional remediation steps. Extend the solution as needed for your organization.
- See [HIPAA_GDPR_COMPLIANCE.md](docs/HIPAA_GDPR_COMPLIANCE.md) for full details and usage examples.

---

This accelerator provisions a reference implementation of a Data & Analytics Hub
on Azure and Microsoft Fabric using Infrastructure-as-Code (IaC) with Terraform.

It is fully parameterized and supports deployment for any organization by configuring variables in `terraform.tfvars`.

## Features

- Terraform-first deployment of Azure + Microsoft Fabric resources
- Supports Dev / QA / Prod environments through variables
- Optional modules so admins can choose which components to deploy
- Implements a Medallion-style data lake (Bronze / Silver / Gold) in ADLS for landing +
  staging data that feeds Microsoft Fabric OneLake
- Creates monitoring, logging, and Purview governance primitives
- Provides a starter Azure DevOps pipeline for CI/CD
- **Fully parameterized**: no hardcoded company names or project identifiers
- Multi-tenant ready: deploy for any organization by changing variables

## Prerequisites

- Terraform v1.3+ (tested with 1.5.x; should work with later 1.x versions)
- An Azure subscription and permissions to create resources
- A service principal with `Contributor` rights on the subscription

Export the following environment variables before running terraform:

```powershell
$env:ARM_CLIENT_ID     = "<service-principal-app-id>"
$env:ARM_CLIENT_SECRET = "<service-principal-password>"
$env:ARM_TENANT_ID     = "<aad-tenant-id>"
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
```

## Directory Layout

- `main.tf` / `variables.tf` / `outputs.tf` - root composition
- `modules/*` - reusable modules for individual building blocks
- `ci-cd/azure-pipelines.yml` - example Azure DevOps pipeline
- `terraform.tfvars.example` - sample configuration for one environment
- Fabric capacity administration requires Azure AD user or service principal object IDs (Enterprise applications > <app> > Object ID). Group object IDs are rejected by the Fabric API.

## Quick Start (Windows, terraform.exe)

From PowerShell:

```powershell
cd <path-to-cloned-or-unzipped-accelerator>

# 1. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
#   -> open terraform.tfvars and adjust values (prefix, location, environment, etc.)

# 2. Initialize providers and modules
terraform.exe init

# 3. See what will be created
terraform.exe plan

# 4. Apply changes
terraform.exe apply

# 5. Destroy (if you want to clean up the environment)
terraform.exe destroy
```

Module usage is controlled via boolean flags in `terraform.tfvars` (e.g. `enable_fabric = true`,
`enable_purview = false`, etc.), so you can pick and choose which resources to deploy.

> **NOTE:** This accelerator is opinionated and meant as a starting point. You should
> review, extend, and harden it for your specific organizational policies.

## Example Deployment Script (Windows, PowerShell)

The following script demonstrates a typical deployment workflow for both INFRA and FABRIC directories:

```powershell
az login

# INFRA
.\terraform --% -chdir=infra init
.\terraform --% -chdir=infra plan -out=tfplan -var-file=../terraform.tfvars
.\terraform --% -chdir=infra apply tfplan

# FABRIC
.\terraform --% -chdir=fabric init
.\terraform --% -chdir=fabric plan -out=tfplan -var-file=../terraform.tfvars
.\terraform --% -chdir=fabric apply tfplan
```

## Parameterization & Multi-Tenant Support

All resource names, display names, and descriptions are generated from variables:
- `prefix`: lowercase, alphanumeric, used in Azure resource names
- `company_name`: used in display names and descriptions
- `project_name`: used in tags and documentation
- `environment`: used in resource names and tags

You can override auto-generated names for backward compatibility or migration.
See `PARAMETERIZATION_GUIDE.md` and `VARIABLE_REFERENCE.md` for details.

## Policy-as-Code (OPA / Conftest)

This repo includes a baseline policy pack under `policy/` intended to catch common
security, compliance, and governance issues early from Terraform plan output.

### How policies run in CI

The Azure DevOps pipeline (`ci-cd/azure-pipelines.yml`) generates `plan.json` for both
Terraform roots (`infra/` and `fabric/`) and runs:

- `conftest test --policy policy infra/plan.json`
- `conftest test --policy policy fabric/plan.json`

Policy enforcement is controlled by the pipeline variable `enforcePolicies`:

- `true`: fail the pipeline on policy violations (production-ready default)
- `false`: audit-only (reports are still published)

### Run policies locally

1. Generate a plan JSON:

```powershell
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
```

2. Run Conftest:

```powershell
conftest test --policy policy plan.json -o table
```

## Documentation

- See `IMPLEMENTATION_SUMMARY.md` for a summary of recent changes
- See `PARAMETERIZATION_GUIDE.md` for migration and usage guidance
- See `VARIABLE_REFERENCE.md` for a full list of supported variables and patterns
- See [HIPAA_GDPR_COMPLIANCE.md](./HIPAA_GDPR_COMPLIANCE.md) for compliance automation details

## Azure Service Principal and Admin Account Setup

To deploy Microsoft Fabric resources, you must provide:
- A Service Principal (SP) with Contributor rights on your Azure subscription
- At least one Azure AD (Entra ID) user account with admin rights for Fabric

### 1. Create a Service Principal

Run the following command in Azure CLI:

```powershell
az ad sp create-for-rbac --name "fabric-terraform-sp" --role Contributor --scopes /subscriptions/<your-subscription-id>
```

This will output values for `client_id`, `client_secret`, and `tenant_id` to use in your `terraform.tfvars`.

### 2. Get the Service Principal Object ID

```powershell
az ad sp show --id <appId-from-above> --query objectId -o tsv
```

Use this value in the `fabric_admin_object_ids` array.

### 3. Add a User Admin Account

You must also provide at least one Azure AD user UPN (email) with admin rights for Fabric. Do not use group object IDs.

### 4. Example Configuration

```hcl
fabric_admin_object_ids = [
  "00000000-0000-0000-0000-000000000001", # Service principal object ID
  #"00000000-0000-0000-0000-000000000002" # Optional: Entra ID user object ID
]

fabric_admin_upns = [
  "adminuser@yourdomain.com"
  # Add more valid UPNs or service principal object IDs as needed, but do not include group object IDs
]
```

> **Note:** Do not use group object IDs. Only user or service principal object IDs are supported for Fabric admin assignment.

## Downloading Terraform (Free Version)

This accelerator uses the free/open-source version of Terraform to provide a low/no-cost solution for Infrastructure-as-Code (IaC) deployments on Azure and Microsoft Fabric. The free version is fully capable for most enterprise scenarios and does not require any paid license or subscription.

### Why Free Version?
- No cost for users or organizations
- Most core IaC features are available
- No dependency on paid Terraform Cloud or Enterprise features
- Enables maximum accessibility and flexibility

### Download Instructions
Visit the official HashiCorp Terraform download page:
https://developer.hashicorp.com/terraform/install

#### Windows (AMD64)
1. Go to the [Terraform Install Page](https://developer.hashicorp.com/terraform/install)
2. Download the Windows AMD64 zip file
3. Extract and place `terraform.exe` in a directory included in your system `PATH`

#### Other Operating Systems
- **macOS:** Download the appropriate zip for your architecture and extract to `/usr/local/bin` or another directory in your `PATH`
- **Linux:** Download the Linux zip for your architecture and extract to `/usr/local/bin` or another directory in your `PATH`

### Why PowerShell + Terraform?
- PowerShell is included by default on Windows and available on other platforms
- Enables scripting, automation, and orchestration of Terraform commands
- No need for additional paid automation tools
- Demonstrates ingenuity and practical, low-cost DevOps for Azure and Microsoft Fabric

> **The Accelerator showcases how to achieve robust, enterprise-grade IaC deployments with zero licensing cost, using only free tools and built-in scripting capabilities.**

> **Note:** This solution provides a strong starting point for compliance automation, but is not a full end-to-end IaC and compliance guarantee. Users should review, validate, and extend the solution to meet their organization's specific requirements.

## Authors
- Created by Hans Esquivel