terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.10.0"
    }
  }
}
