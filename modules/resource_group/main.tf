variable "prefix" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

output "name" {
  value = azurerm_resource_group.this.name
}

output "id" {
  value       = azurerm_resource_group.this.id
  description = "Resource ID of the resource group."
}