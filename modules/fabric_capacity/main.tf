#############################################
# modules/fabric_capacity/main.tf
#############################################

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID where the Fabric Capacity will be created."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for Fabric capacity."
}

variable "location" {
  type        = string
  description = "Azure region for Fabric capacity."
}

variable "prefix" {
  type        = string
  description = "Name prefix."
}

variable "environment" {
  type        = string
  description = "Environment (dev/qa/prod)."
}

variable "sku_name" {
  type        = string
  description = "Fabric capacity SKU name (e.g. F2, F4, F8, F64, F128...)."
}

variable "tags" {
  description = "Tags applied to the Fabric Capacity."
  type        = map(string)
  default     = {}
}

variable "fabric_admin_object_ids" {
  type        = list(string)
  description = "Entra ID Object IDs for Fabric Capacity admins (must be users or service principals; NOT groups)."
  default     = []  
}

variable "fabric_admin_upns" {
  type = list(string)
}

variable "capacity_name" {
  type        = string
  description = "Fabric capacity resource name. Must match ^[a-z][a-z0-9]*$"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]*$", var.capacity_name))
    error_message = "capacity_name must match ^[a-z][a-z0-9]*$ (lowercase alphanumeric, starting with a letter)."
  }
}

variable "fabric_sku_name" {
  type        = string
  description = "Fabric capacity SKU name (e.g. F2, F4, F8, F64...)."
}

resource "azapi_resource" "fabric_capacity" {
  # Use supported stable API version
  type      = "Microsoft.Fabric/capacities@2023-11-01"
  name      = "${replace(var.prefix, "-", "")}${var.environment}fabriccapacity"     # var.capacity_name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}" #var.resource_group_id
  location  = var.location

  # Keep schema validation off if azapi schema lags, but the body must still match what ARM expects.
  schema_validation_enabled = false

  # IMPORTANT: members must be ["<objectId>", ...] (strings)
  body = jsonencode({
      properties = {
        administration = {
          members = concat(var.fabric_admin_upns, var.fabric_admin_object_ids)
        }
      }
      sku = {
        name = var.fabric_sku_name
        tier = "Fabric"
      }
      # tags = var.tags
    })
}

output "id" {
  description = "Resource ID of the Fabric capacity."
  value       = azapi_resource.fabric_capacity.id
}

output "name" {
  description = "Fabric capacity ARM name."
  value       = azapi_resource.fabric_capacity.name
}
