package accelerator.naming

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

# Naming Guardrails
# -----------------
# Baseline naming rules that prevent common Azure API failures.
#

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_resource_group"

  name := lower(tf.resource_name(rc))
  not tf.is_kebab_lower(name)

  msg := sprintf("Resource group name '%v' must be lowercase kebab-case (a-z, 0-9, '-')", [tf.resource_name(rc)])
}

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_storage_account"

  name := lower(tf.resource_name(rc))
  not tf.is_storage_name(name)

  msg := sprintf("Storage account name '%v' must match ^[a-z0-9]{3,24}$", [tf.resource_name(rc)])
}
