#############################################
# infra/main.tf
#############################################

locals {
  # Construct capacity name if not explicitly provided
  fabric_capacity_name = var.fabric_capacity_name != "" ? var.fabric_capacity_name : "${var.prefix}${var.environment}fabriccapacity"
}

#############################################
# Resource Group
#############################################

module "resource_group" {
  source = "../modules/resource_group"

  prefix      = var.prefix
  environment = var.environment
  location    = var.location
  tags        = var.tags
}

#############################################
# Networking
#############################################

module "networking" {
  source = "../modules/networking"
  count  = var.enable_networking ? 1 : 0

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags
}

#############################################
# Log Analytics
#############################################

module "log_analytics" {
  source = "../modules/log_analytics"
  count  = var.enable_log_analytics ? 1 : 0
  retention_days = var.log_analytics_retention_days

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags
}

#############################################
# Key Vault
#############################################

module "key_vault" {
  source = "../modules/key_vault"
  count  = var.enable_key_vault ? 1 : 0

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tenant_id           = var.tenant_id
  tags                = var.tags

  log_analytics_workspace_id = var.enable_log_analytics ? module.log_analytics[0].workspace_id : null
}

#############################################
# Storage Medallion (Bronze/Silver/Gold)
#############################################

module "storage_medallion" {
  source = "../modules/storage_medallion"
  count  = var.enable_storage_medallion ? 1 : 0

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags

  log_analytics_workspace_id = var.enable_log_analytics ? module.log_analytics[0].workspace_id : null
}

#############################################
# Purview
#############################################

module "purview" {
  source = "../modules/purview"
  count  = var.enable_purview ? 1 : 0

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags
}

#############################################
# Data Factory
#############################################

module "data_factory" {
  source = "../modules/data_factory"
  count  = var.enable_data_factory ? 1 : 0

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags

  storage_account_name = try(module.storage_medallion[0].storage_account_name, null)

  log_analytics_workspace_id = var.enable_log_analytics ? module.log_analytics[0].workspace_id : null
}

#############################################
# API Management
#############################################

module "api_management" {
  source = "../modules/api_management"
  count  = var.enable_api_management ? 1 : 0

  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  environment         = var.environment
  tags                = var.tags
  
  publisher_name      = var.company_name
  publisher_email     = "admin@${lower(var.company_name)}.com"
}

#############################################
# Microsoft Fabric Capacity (AzAPI)
#############################################

module "fabric_capacity" {
  source = "../modules/fabric_capacity"
  count  = var.enable_fabric ? 1 : 0

  resource_group_id					= module.resource_group.id
  location							= var.location
  capacity_name						= local.fabric_capacity_name
  fabric_sku_name					= var.fabric_sku_name
  fabric_admin_object_ids			= var.fabric_admin_object_ids
  fabric_admin_upns					= var.fabric_admin_upns

  subscription_id					= var.subscription_id
  resource_group_name				= module.resource_group.name  
  prefix							= var.prefix
  environment						= var.environment
  sku_name							= var.fabric_sku_name  
}

#############################################
# Outputs
#############################################

output "resource_group_name" {
  value = module.resource_group.name
}

output "fabric_capacity_name" {
  value       = local.fabric_capacity_name
  description = "Name of the Fabric capacity as seen in Fabric and used by the Fabric Terraform root."
}
