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

resource "azurerm_purview_account" "this" {
  name                = "${var.prefix}-${var.environment}-purview"
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

output "id" {
  description = "Purview account ID."
  value       = azurerm_purview_account.this.id
}
