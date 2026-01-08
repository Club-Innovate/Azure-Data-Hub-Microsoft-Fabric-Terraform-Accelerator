variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

variable "log_analytics_workspace_id" {
  type        = string
  description = "Optional Log Analytics workspace id for diagnostics."
  default     = null
}

variable "storage_account_name" {
  type        = string
  description = "Optional storage account name used by sample pipeline."
  default     = null
}

resource "random_string" "adf_suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_data_factory" "this" {
  name                = "${var.prefix}-${var.environment}-adf${random_string.adf_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "adf" {
  name                       = "diag-adf"
  target_resource_id         = azurerm_data_factory.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy/providers/Microsoft.OperationalInsights/workspaces/dummy"

  enabled_log {
    category = "ActivityRuns"
  }

  enabled_log {
    category = "PipelineRuns"
  }

  enabled_log {
    category = "TriggerRuns"
  }

  enabled_log {
    category = "SandboxActivityRuns"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [log_analytics_workspace_id]
  }

  depends_on = [azurerm_data_factory.this]
}

output "data_factory_name" {
  value = azurerm_data_factory.this.name
}
