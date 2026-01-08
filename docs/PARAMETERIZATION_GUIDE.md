# Parameterization Migration Guide

## Overview
This guide explains how to use the accelerator for any organization by configuring variables. All hardcoded company/project names have been removed.

## What Changed
- New variables: `company_name`, `project_name`, `prefix`, `environment`.
- Resource names and display names are auto-generated from variables.
- Backward compatibility: override auto-generated names if needed.

## Migration Steps

### Maintain Existing Names
Set variables in `terraform.tfvars` to match your current deployment. No resources will be recreated.

### Migrate to New Organization
Update variables for your new company. Resources will be recreated with new names. Backup data before applying.

## New Deployment
Copy `terraform.tfvars.example` and update organization-specific values. Run standard Terraform workflow.

## Auto-Generated Resource Names
| Resource | Pattern | Example |
|----------|---------|---------|
| Fabric Capacity | `{prefix}{environment}fabriccapacity` | `avatardevfabriccapacity` |
| Workspace Display Name | `{company_name} {Title(environment)} Fabric Workspace` | `avatar Dev Fabric Workspace` |
| Storage Account | `{prefix}{environment}sa` | `avatardevsa` |
| Data Factory | `{prefix}-{environment}-adf` | `avatar-dev-adf` |
| API Management | `{prefix}-{environment}-apim` | `avatar-dev-apim` |
| Resource Group | `{prefix}-{environment}-rg` | `avatar-dev-rg` |

## Validation
- Run `terraform fmt -check` and `terraform validate` in each root.
- Review planned changes before applying.

## Documentation
- See `VARIABLE_REFERENCE.md` for all supported variables and patterns.
- See `IMPLEMENTATION_SUMMARY.md` for a summary of changes.

## Authors
- Created by Hans Esquivel
