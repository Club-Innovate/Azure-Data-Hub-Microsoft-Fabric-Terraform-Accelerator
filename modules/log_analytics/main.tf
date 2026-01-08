variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "environment" { type = string }
variable "retention_days" { type = number }
variable "tags" { type = map(string) }

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.tags
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}
