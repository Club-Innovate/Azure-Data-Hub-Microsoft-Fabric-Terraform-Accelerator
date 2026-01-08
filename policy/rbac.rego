package accelerator.rbac

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

# Identity / Access Guardrails (baseline)
# ---------------------------------------
# Secure-by-default platform controls.
#

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_key_vault"

  a := tf.after(rc)

  (a.soft_delete_retention_days == null) or (a.soft_delete_retention_days < 7)

  msg := sprintf("Key Vault '%v' soft_delete_retention_days must be set and >= 7", [tf.resource_name(rc)])
}

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_key_vault"

  a := tf.after(rc)
  a.purge_protection_enabled != true

  msg := sprintf("Key Vault '%v' must have purge_protection_enabled = true", [tf.resource_name(rc)])
}
