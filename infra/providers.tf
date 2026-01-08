terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~> 1.10.0"
    }

    fabric = {
      source  = "microsoft/fabric"
      version = ">= 0.1.0-rc.2"
    }
  }
}

provider "azurerm" {
  features {}

  # Use variables so you can override via terraform.tfvars / pipeline vars
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

# Do NOT use Managed Identity on this Windows box (Arc agent file issue)
# Reuse the Azure CLI session instead (same as azurerm)
provider "azapi" {
  use_msi = false
  use_cli = true

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}