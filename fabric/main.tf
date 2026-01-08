#############################################
# Discover existing Fabric Capacity (by name)
#############################################

locals {
  # Construct capacity name if not explicitly provided
  fabric_capacity_name = var.fabric_capacity_name != "" ? var.fabric_capacity_name : "${var.prefix}${var.environment}fabriccapacity"
  
  # Construct workspace display name if not explicitly provided
  fabric_workspace_display_name = var.fabric_workspace_display_name != "" ? var.fabric_workspace_display_name : "${var.company_name} ${title(var.environment)} Fabric Workspace"
}

data "fabric_capacity" "this" {
  display_name = local.fabric_capacity_name
}

#############################################
# Workspace (module uses Fabric provider)
#############################################

module "fabric_workspace" {
  source = "../modules/fabric_workspace"

  display_name = local.fabric_workspace_display_name
  description  = "${var.company_name} ${var.environment} Fabric workspace (Medallion hub)"
  capacity_id  = data.fabric_capacity.this.id

  providers = {
    fabric = fabric
  }
}

locals {
  # Extract the workspace GUID from the ARM resource ID (last segment after '/')
  workspace_guid = regex("[^/]+$", module.fabric_workspace.id)
}

#############################################
# Lakehouse (Medallion anchored workspace)
#############################################

module "fabric_lakehouse" {
  source = "../modules/fabric_lakehouse"
  count  = var.enable_fabric_lakehouse ? 1 : 0

  # Pass the workspace GUID, not the ARM resource ID
  workspace_id   = local.workspace_guid
  lakehouse_name = "${var.prefix}_${var.environment}_lakehouse"
  tenant_id      = var.tenant_id
  client_id      = var.client_id
  client_secret  = var.client_secret

  providers = {
    fabric = fabric
  }

  depends_on = [
    null_resource.add_workspace_admin,
    null_resource.add_sp_contributor
  ]
}

resource "null_resource" "add_workspace_admin" {
  count = length(var.fabric_admin_upns)
  provisioner "local-exec" {
    # Pass the workspace GUID, not the ARM resource ID
    command = "pwsh ./scripts/add_workspace_admin.ps1 -WorkspaceId ${local.workspace_guid} -UserToAdd ${var.fabric_admin_upns[count.index]} -AccessRight Admin -PrincipalType User"
  }
  depends_on = [module.fabric_workspace]
}

resource "null_resource" "add_sp_contributor" {
  count = length(var.fabric_admin_object_ids)
  provisioner "local-exec" {
    command = "pwsh ./scripts/add_workspace_admin.ps1 -WorkspaceId ${local.workspace_guid} -UserToAdd ${var.fabric_admin_object_ids[count.index]} -AccessRight Contributor -PrincipalType App"
  }
  depends_on = [module.fabric_workspace]
}

#############################################
# Outputs
#############################################

output "fabric_capacity_id" {
  description = "Fabric capacity GUID as known to the Fabric control plane."
  value       = data.fabric_capacity.this.id
}

output "fabric_workspace_id" {
  description = "Fabric workspace ID."
  value       = module.fabric_workspace.id
}

output "debug_workspace_id" {
  value = module.fabric_workspace.id
}
