package accelerator.regions

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

#
# Region Guardrails
# -----------------
# Enforces allowed regions for key platform resources.
#

region_scoped_types := {
  "azurerm_resource_group",
  "azurerm_storage_account",
  "azurerm_key_vault",
  "azurerm_log_analytics_workspace",
  "azurerm_data_factory",
}

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type in region_scoped_types

  a := tf.after(rc)
  loc := tf.location(a)

  loc != ""
  not tf.approved_regions[loc]

  allowed := sort([r | r := tf.approved_regions[_]])
  msg := sprintf("Unapproved region '%v' for %v '%v' (allowed: %v)", [loc, rc.type, tf.resource_name(rc), allowed])
}
