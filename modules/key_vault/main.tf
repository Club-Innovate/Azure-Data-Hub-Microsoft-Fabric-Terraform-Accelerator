variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "environment" { type = string }
variable "tenant_id" { type = string }
variable "tags" { type = map(string) }

variable "log_analytics_workspace_id" {
  type        = string
  description = "Optional Log Analytics workspace id for diagnostics."
  default     = null
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs allowed to access the Key Vault."
  default     = []
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  kv_name = lower("${var.prefix}${var.environment}kv${random_string.suffix.result}")
}

resource "azurerm_key_vault" "kv" {
  #name                        = "${var.prefix}${var.environment}kv"
  name                        = local.kv_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  enabled_for_deployment      = false
  enabled_for_disk_encryption = false
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    # You can add your subnet/service endpoint here for allowed access
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy/providers/Microsoft.OperationalInsights/workspaces/dummy"

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [log_analytics_workspace_id]
  }

  depends_on = [azurerm_key_vault.kv]
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
