#############################################
# HIPAA Compliance Policy Assignment Module
#############################################
# This module assigns the built-in Azure Policy initiative for HIPAA/HITECH compliance
# at the specified scope (resource group or resource).
#
# Inputs:
#   - scope_id: The Azure resource ID for assignment (resource group or resource)
#   - scope_type: "resource_group" or "resource"
#   - location: Azure region for the managed identity
#
# Outputs:
#   - assignment_id: The ID of the policy assignment
#############################################

variable "scope_id" {
  description = "The Azure resource ID to assign the HIPAA policy initiative to."
  type        = string
}

variable "scope_type" {
  description = "Type of scope for policy assignment: 'resource_group' or 'resource'."
  type        = string
  default     = "resource_group"
}

variable "location" {
  description = "Azure region for the managed identity."
  type        = string
}

data "azurerm_policy_set_definition" "hipaa" {
  name = "a169a624-5599-4385-a696-c8d643089fab"
}

resource "azurerm_resource_group_policy_assignment" "hipaa" {
  count                = var.scope_type == "resource_group" ? 1 : 0
  name                 = "hipaa-hitech-compliance"
  display_name         = "HIPAA/HITECH Compliance Policy"
  policy_definition_id = data.azurerm_policy_set_definition.hipaa.id
  resource_group_id    = var.scope_id
  description          = "Assigns the built-in HIPAA/HITECH compliance policy initiative at resource group scope."
  location             = var.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_resource_policy_assignment" "hipaa" {
  count                = var.scope_type == "resource" ? 1 : 0
  name                 = "hipaa-hitech-compliance"
  display_name         = "HIPAA/HITECH Compliance Policy"
  policy_definition_id = data.azurerm_policy_set_definition.hipaa.id
  resource_id          = var.scope_id
  description          = "Assigns the built-in HIPAA/HITECH compliance policy initiative at resource scope."
  location             = var.location
  identity {
    type = "SystemAssigned"
  }
}

output "assignment_id" {
  value = var.scope_type == "resource_group" ? azurerm_resource_group_policy_assignment.hipaa[0].id : azurerm_resource_policy_assignment.hipaa[0].id
}
