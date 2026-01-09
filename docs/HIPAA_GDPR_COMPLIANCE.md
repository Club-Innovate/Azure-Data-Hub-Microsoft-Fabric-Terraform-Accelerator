# HIPAA & GDPR Compliance Features

This solution now supports automated enforcement of HIPAA and GDPR compliance policies using Azure Policy initiatives, fully integrated into the Terraform deployment process.

## Overview
- **HIPAA/HITECH** and **GDPR** compliance can be enabled via simple variables.
- Built-in Azure Policy initiatives are assigned at the resource group or resource level.
- Diagnostic settings, network restrictions, and other controls are automatically configured for key resources.
- Post-deployment compliance validation is supported via PowerShell.

## How It Works
- Set the following variables in your `terraform.tfvars`:
  - `enable_hipaa = true` to enable HIPAA/HITECH compliance
  - `enable_gdpr = true` to enable GDPR compliance
  - `compliance_scope = "resource_group"` or `"resource"` to control assignment scope
- The deployment will:
  - Assign the relevant Azure Policy initiative
  - Configure managed identity for remediation
  - Lock down network access and enable diagnostics for core resources

## Key Variables
| Variable            | Type    | Description                                                      |
|---------------------|---------|------------------------------------------------------------------|
| enable_hipaa        | bool    | Enable HIPAA/HITECH compliance policy enforcement                |
| enable_gdpr         | bool    | Enable GDPR compliance policy enforcement                        |
| compliance_scope    | string  | Scope for policy assignment: 'resource_group' or 'resource'      |

## Example `terraform.tfvars`
```hcl
enable_hipaa = true
enable_gdpr  = false
compliance_scope = "resource_group"
```

## Automated Remediation
- Storage accounts and Key Vaults are locked down for public access.
- Subnets are associated with NSGs and service endpoints as required.
- Diagnostic settings are enabled for all core resources.
- A PowerShell script (`scripts/lockdown_storage.ps1`) is automatically run post-deployment to enforce storage lockdown for HIPAA.

## Compliance Validation
- Use `scripts/validate-compliance.ps1` to check compliance status after deployment.
- The script outputs a summary of compliant and non-compliant resources for HIPAA and GDPR.

## Extending and Validating Compliance
- **Review the policies assigned in the Azure Portal** under Policy Assignments for your resource group.
- **Run the validation script** to identify which resources are non-compliant or require additional remediation.
- **Manual Remediation:** Some Azure Policy initiatives may require manual remediation steps or additional configuration not covered by this accelerator.
- **Extend the Solution:** You can add more policies, custom initiatives, or scripts to cover additional compliance requirements (e.g., GLBA, PCI-DSS) as needed.
- **Note:** This solution provides a strong starting point for compliance automation, but is not a full end-to-end compliance guarantee. Users should review, validate, and extend the solution to meet their organization's specific requirements.

---

For more details, see the main README and the compliance modules in `modules/compliance/`.

## Authors
- Created by Hans Esquivel