# Scripts Guide

This guide provides an overview and usage instructions for all PowerShell scripts in the `scripts/` and `fabric/scripts/` folders. These scripts support deployment, automation, and management tasks for the Azure Data Hub & Microsoft Fabric Terraform Accelerator.

## Overview

Scripts are provided for:
- Deployment and compliance automation
- Resource management (e.g., Purview, storage lockdown)
- Microsoft Fabric workspace and lakehouse operations
- Testing and validation (integration, smoke, compliance)

Scripts are intended for manual execution or local automation. Most are not designed for direct use in CI/CD pipelines, but can be adapted if needed.

## scripts/

| Script                      | Purpose                                                                                 |
|-----------------------------|-----------------------------------------------------------------------------------------|
| `check_purview.ps1`         | Checks for existing Azure Purview accounts in a subscription. Outputs JSON for Terraform.|
| `lockdown_storage.ps1`      | Disables public network access on a storage account for HIPAA compliance.               |
| `test_integration.ps1`      | Full integration test: plans, applies, policy gates, and (optionally) destroys resources.|
| `test_smoke.ps1`            | Safe smoke test: validates structure, runs plan/policy checks, no apply/destroy.        |
| `validate-compliance.ps1`   | Validates Azure Policy compliance (HIPAA, GDPR) for a given scope.                      |

### Usage Examples

#### `check_purview.ps1`
Checks if a Purview account exists in your Azure subscription. Outputs JSON for use with Terraform external data sources.
```powershell
./scripts/check_purview.ps1 -SubscriptionId "<sub-id>" -TenantId "<tenant-id>" -ClientId "<app-id>" -ClientSecret "<secret>"
```

#### `lockdown_storage.ps1`
Disables public network access for a specified storage account (HIPAA compliance).
```powershell
./scripts/lockdown_storage.ps1 -StorageAccountName "avatardevsa" -ResourceGroupName "avatar-dev-rg"
```

#### `test_integration.ps1`
Runs a full integration test: plans, applies, runs policy gates, and (by default) destroys resources at the end. Use a test subscription!
```powershell
./scripts/test_integration.ps1
# To skip destroy:
./scripts/test_integration.ps1 -SkipDestroy
```

#### `test_smoke.ps1`
Runs a safe, plan-only smoke test: validates repo structure, runs terraform plan, and policy checks. No resources are created or destroyed.
```powershell
./scripts/test_smoke.ps1
```

#### `validate-compliance.ps1`
Checks Azure Policy compliance for HIPAA and GDPR at a given scope (subscription/resource group).
```powershell
./scripts/validate-compliance.ps1 -ScopeId "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
```

## fabric/scripts/

| Script                          | Purpose                                                                                   |
|----------------------------------|-------------------------------------------------------------------------------------------|
| `add_workspace_admin.ps1`        | Adds a user or service principal as admin to a Fabric workspace via REST API.              |
| `create_fabric_lakehouse.ps1`    | Creates a Fabric Lakehouse in a workspace using the Fabric REST API.                       |
| `fabric_notebook_utils.ps1`      | Helper functions for creating and running Fabric notebooks (used by other scripts).         |
| `_verify_notebook.ps1`           | Verifies notebook JSON structure and outputs debug info (for development/testing).          |

### Usage Examples

#### `add_workspace_admin.ps1`
Adds a user or service principal as admin to a Fabric workspace.
```powershell
./fabric/scripts/add_workspace_admin.ps1 -WorkspaceId "<workspace-id>" -UserToAdd "<object-id-or-upn>" -AccessRight "Admin" -PrincipalType "User"
```

#### `create_fabric_lakehouse.ps1`
Creates a Fabric Lakehouse in the specified workspace.
```powershell
./fabric/scripts/create_fabric_lakehouse.ps1 -TenantId "<tenant-id>" -ClientId "<app-id>" -ClientSecret "<secret>" -WorkspaceId "<workspace-id>" -LakehouseName "<name>"
```

#### `fabric_notebook_utils.ps1`
Provides helper functions for notebook creation and execution. Typically imported by other scripts.

#### `_verify_notebook.ps1`
Verifies the structure of a generated notebook JSON (for development/testing).
```powershell
./fabric/scripts/_verify_notebook.ps1
```

## Notes
- Scripts may require Azure CLI authentication (`az login`) and appropriate permissions.
- For Fabric REST API scripts, ensure your service principal has Contributor rights and API access.
- Scripts are intended for manual/local use, but can be adapted for automation as needed.

## See Also
- [README.md](../README.md) for accelerator overview and quick start
- [PARAMETERIZATION_GUIDE.md](PARAMETERIZATION_GUIDE.md) for variable usage
- [VARIABLE_REFERENCE.md](VARIABLE_REFERENCE.md) for naming patterns
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for recent changes

---
