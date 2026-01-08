package accelerator.tags

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

# Tagging Guardrails
# ------------------
# Enforces required tags on governed resources.
#

tag_scoped_types := {
  "azurerm_resource_group",
  "azurerm_storage_account",
  "azurerm_key_vault",
  "azurerm_log_analytics_workspace",
  "azurerm_data_factory",
}

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type in tag_scoped_types

  a := tf.after(rc)
  t := tf.tags(a)

  missing := tf.missing_keys(t, tf.required_tags)
  count(missing) > 0

  msg := sprintf("%v '%v' missing required tags: %v", [rc.type, tf.resource_name(rc), missing])
}
