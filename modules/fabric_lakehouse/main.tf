terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
    }
  }
}

#############################################
# Fabric Lakehouse Helper (Experimental)
#
# This module demonstrates how you might call
# the Microsoft Fabric REST API from Terraform
# via a local-exec provisioner to create a
# Lakehouse inside an existing Fabric workspace.
#
# IMPORTANT:
#  - Requires Azure CLI installed on the machine
#    running terraform.
#  - Requires that the logged-in identity has
#    permissions to the Fabric workspace.
#  - This uses local-exec and is therefore not
#    fully idempotent; treat it as a helper.
#############################################

variable "workspace_id" {
  description = "The ARM resource ID of the Fabric workspace."
  type        = string
}

variable "lakehouse_name" {
  description = "Name of the Lakehouse to create."
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID."
  type        = string
}

variable "client_id" {
  description = "The Azure client ID."
  type        = string
}

variable "client_secret" {
  description = "The Azure client secret."
  type        = string
}

# Null resource that triggers when the desired lakehouse name changes.
resource "null_resource" "fabric_lakehouse" {
  triggers = {
    workspace_id   = var.workspace_id
    lakehouse_name = var.lakehouse_name
    tenant_id      = var.tenant_id
    client_id      = var.client_id
    client_secret  = var.client_secret
  }

  provisioner "local-exec" {
    when    = create
    command = "pwsh ./scripts/create_fabric_lakehouse.ps1 -WorkspaceId ${var.workspace_id} -LakehouseName ${var.lakehouse_name} -TenantId ${var.tenant_id} -ClientId ${var.client_id} -ClientSecret ${var.client_secret}"
  }
}

output "lakehouse_name" {
  description = "Name of the Lakehouse requested for creation."
  value       = var.lakehouse_name
}
