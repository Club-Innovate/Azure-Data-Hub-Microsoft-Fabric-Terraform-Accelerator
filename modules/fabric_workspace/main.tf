#############################################
# modules/fabric_workspace/main.tf
#############################################

terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = ">= 0.1.0-rc.2"
    }
  }
}

variable "display_name" {
  description = "Display name of the Fabric workspace."
  type        = string
}

variable "description" {
  description = "Description for the Fabric workspace."
  type        = string
  default     = ""
}

variable "capacity_id" {
  description = "Fabric capacity GUID to host this workspace."
  type        = string
}

resource "fabric_workspace" "this" {
  display_name = var.display_name
  description  = var.description
  capacity_id  = var.capacity_id

  # Optional identity block if/when supported by the provider
  # identity = {
  #   type = "SystemAssigned"
  # }
}

output "id" {
  description = "ID of the Fabric workspace."
  value       = fabric_workspace.this.id
}
