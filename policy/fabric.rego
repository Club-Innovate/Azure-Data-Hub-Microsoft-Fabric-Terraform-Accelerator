package accelerator.fabric

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

#
# Microsoft Fabric Guardrails
# ---------------------------
# - Fabric Capacity is commonly created via AzAPI:
#       azapi_resource with after.type like "Microsoft.Fabric/capacities@2023-11-01"
# - Fabric Workspace/Lakehouse may be created with microsoft/fabric provider:
#       resource type like "fabric_workspace"
#
# These checks are intentionally resilient and avoid brittle schema assumptions.
#

# 1) Fabric Capacity must be in an approved region
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azapi_resource"

  a := tf.after(rc)

  a.type != null
  startswith(lower(a.type), "microsoft.fabric/capacities")

  loc := tf.location(a)
  loc != ""
  not tf.approved_regions[loc]

  msg := sprintf("Fabric Capacity '%v' uses unapproved region '%v'", [tf.resource_name(rc), loc])
}

# 2) Fabric Capacity must specify a valid SKU name (prevents 'SKU N/A' issues)
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azapi_resource"

  a := tf.after(rc)
  a.type != null
  startswith(lower(a.type), "microsoft.fabric/capacities")

  a.body != null
  body := json.unmarshal(a.body)

  (body.sku == null) or (body.sku.name == null) or (trim(body.sku.name) == "")

  msg := sprintf("Fabric Capacity '%v' must set body.sku.name to a valid Fabric SKU (e.g., F2/F4/F8...)", [tf.resource_name(rc)])
}

# 3) Fabric Workspace must reference a capacity_id (provider: microsoft/fabric)
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "fabric_workspace"

  a := tf.after(rc)

  (a.capacity_id == null) or (trim(a.capacity_id) == "")

  msg := sprintf("Fabric Workspace '%v' must be bound to a capacity_id", [tf.resource_name(rc)])
}
