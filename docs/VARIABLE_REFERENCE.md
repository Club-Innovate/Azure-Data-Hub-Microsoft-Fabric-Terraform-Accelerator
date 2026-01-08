# Variable Reference Guide

Quick reference for all parameterization variables in the Terraform Fabric Accelerator.

## Core Variables

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `prefix` | string | "avatar" | Resource names (lowercase, alphanumeric) |
| `company_name` | string | "avatar" | Display names, descriptions |
| `project_name` | string | "Data-Hub" | Tags, documentation |
| `environment` | string | "dev" | Resource names, tags |

## Auto-Generated Names

| Variable | Pattern | Example |
|----------|---------|---------|
| `fabric_capacity_name` | `{prefix}{environment}fabriccapacity` | `avatardevfabriccapacity` |
| `fabric_workspace_display_name` | `{company_name} {Title(environment)} Fabric Workspace` | `avatar Dev Fabric Workspace` |

## Resource Naming Patterns

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `{prefix}-{environment}-rg` | `avatar-dev-rg` |
| Storage Account | `{prefix}{environment}sa` | `avatardevsa` |
| Data Factory | `{prefix}-{environment}-adf` | `avatar-dev-adf` |
| API Management | `{prefix}-{environment}-apim` | `avatar-dev-apim` |

## Override Strategies

- Leave auto-generated names empty for new deployments.
- Set explicit values for backward compatibility.

## Validation Checklist

- `prefix` is lowercase and alphanumeric
- Resource names are within Azure limits
- `company_name` and `environment` are set correctly
- Tags reflect your organization's strategy

## Documentation

- See `PARAMETERIZATION_GUIDE.md` for migration steps
- See `IMPLEMENTATION_SUMMARY.md` for summary of changes

## Authors
- Created by Hans Esquivel
