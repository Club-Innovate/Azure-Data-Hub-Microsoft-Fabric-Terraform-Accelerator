#############################################
# modules/storage_medallion/main.tf
#############################################

variable "resource_group_name" {
  type        = string
  description = "Resource group for the medallion storage account."
}

variable "location" {
  type        = string
  description = "Azure region for the storage account."
}

variable "prefix" {
  type        = string
  description = "Name prefix (e.g. avatar)."
}

variable "environment" {
  type        = string
  description = "Environment (e.g. dev, qa, prod)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to storage resources."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Optional Log Analytics workspace id for diagnostics."
  default     = null
}

data "azurerm_client_config" "current" {}

# Storage account (always created by Terraform)
resource "azurerm_storage_account" "sa" {
  # Example: avatardevsa (must be globally unique & <= 24 chars)
  name                     = "${replace(var.prefix, "-", "")}${var.environment}sa"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true  # Required for ADLS Gen2

  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"  

  # Keep disabled by default; enable only with an explicit exception tag.
  public_network_access_enabled = true

  tags = var.tags
}

# Assign Storage Blob Data Owner to the current principal for this storage account
resource "azurerm_role_assignment" "blob_data_owner" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [azurerm_storage_account.sa]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = "bronze"
  storage_account_id = azurerm_storage_account.sa.id

  # Ensure RBAC is assigned before filesystem creation
  depends_on = [azurerm_storage_account.sa, azurerm_role_assignment.blob_data_owner]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  name               = "silver"
  storage_account_id = azurerm_storage_account.sa.id

  depends_on = [azurerm_storage_account.sa, azurerm_role_assignment.blob_data_owner]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gold" {
  name               = "gold"
  storage_account_id = azurerm_storage_account.sa.id

  depends_on = [azurerm_storage_account.sa, azurerm_role_assignment.blob_data_owner]
}

output "storage_account_name" {
  description = "Name of the medallion storage account."
  value       = azurerm_storage_account.sa.name
}
