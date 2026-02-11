# Azure Data Hub & Microsoft Fabric Terraform Accelerator - Wiki

Welcome to the comprehensive guide for the Azure Data Hub & Microsoft Fabric Terraform Accelerator! This wiki provides in-depth documentation, best practices, and advanced usage scenarios for deploying enterprise-grade data analytics infrastructure on Microsoft Azure and Microsoft Fabric using HashiCorp Terraform and PowerShell automation.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Getting Started](#getting-started)
4. [Core Components](#core-components)
5. [Terraform Modules Reference](#terraform-modules-reference)
6. [PowerShell Automation](#powershell-automation)
7. [Compliance & Security](#compliance--security)
8. [Policy-as-Code with OPA](#policy-as-code-with-opa)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Advanced Usage](#advanced-usage)
11. [Troubleshooting](#troubleshooting)
12. [Best Practices](#best-practices)
13. [Contributing](#contributing)
14. [References](#references)

---

## Introduction

### What is This Accelerator?

The **Azure Data Hub & Microsoft Fabric Terraform Accelerator** is a comprehensive Infrastructure-as-Code (IaC) solution that enables organizations to rapidly deploy and manage modern data analytics infrastructure. Built on **HashiCorp Terraform** and **Microsoft PowerShell**, this accelerator showcases enterprise-grade DevOps practices while maintaining zero licensing costs by leveraging only free, open-source tools.

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
┌─────────────────────────────────────────────────────────────────┐
│                     Microsoft Fabric Layer                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Fabric Capacity  │  │ Fabric Workspace │  │  Lakehouses  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ OneLake Integration
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Infrastructure                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ ADLS Gen2    │  │ Data Factory │  │  Azure Purview       │  │
│  │ (Medallion)  │  │ (Pipelines)  │  │  (Governance)        │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Key Vault    │  │ API Mgmt     │  │  Log Analytics       │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Secure Networking
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Networking & Compliance                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Virtual Net  │  │ NSGs         │  │  Azure Policy        │  │
│  │ (VNet)       │  │ (Security)   │  │  (HIPAA/GDPR)        │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
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

