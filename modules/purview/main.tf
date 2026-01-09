#############################################
# modules/purview/main.tf
#############################################

variable "resource_group_name" {
  type        = string
  description = "Resource group in which to deploy Purview."
}

variable "location" {
  type        = string
  description = "Azure region for the Purview account."
}

variable "prefix" {
  type        = string
  description = "Name prefix."
}

variable "environment" {
  type        = string
  description = "Environment name (dev/qa/prod)."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Purview account."
}

variable "purview_exists" {
  type    = bool
  default = false
}

variable "purview_existing_name" {
  type    = string
  default = ""
}

variable "purview_existing_rg" {
  type    = string
  default = ""
}

resource "random_string" "unique" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_purview_account" "this" {
  count               = var.purview_exists ? 0 : 1
  name                = "${var.prefix}-${var.environment}-purview-${random_string.unique.result}"
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

output "purview_status" {
  value = var.purview_exists ? "Purview already exists: ${var.purview_existing_name} in resource group ${var.purview_existing_rg}" : "Purview created: ${azurerm_purview_account.this[0].name}"
}
