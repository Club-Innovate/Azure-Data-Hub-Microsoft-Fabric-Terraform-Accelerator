package accelerator.diagnostics

import rego.v1
import future.keywords.in

import data.accelerator.tfplan as tf

#
# Diagnostics / Audit Guardrails
# ------------------------------
# Ensures diagnostic settings are configured for core platform resources.
#
# Implementation notes:
# - In Terraform plans, many Azure resource IDs are unknown until apply.
# - `azurerm_monitor_diagnostic_setting.target_resource_id` is often a string *expression*
#   that may not match the computed `after.id` of the target resource at plan time.
# - To keep this production-ready (high-signal, low-noise), we:
#     1) Prefer matching by Terraform reference address when possible.
#     2) Only enforce when we can confidently evaluate the relationship.
#

resource_types_requiring_diagnostics := {
  "azurerm_key_vault",
  "azurerm_storage_account",
  "azurerm_log_analytics_workspace",
  "azurerm_data_factory",
}

# Try to normalize a Terraform address for a resource change.
# Example: "azurerm_storage_account.this" or "module.x.azurerm_key_vault.kv".
resource_addr(rc) := sprintf("%v.%v", [rc.type, rc.name]) if {
  rc.address == null
} else := rc.address if {
  rc.address != null
}

# Collect diagnostic setting targets as strings.
all_diag_target_strings := {lower(t) |
  rc := tf.managed_changes[_]
  rc.type == "azurerm_monitor_diagnostic_setting"
  a := tf.after(rc)
  t := a.target_resource_id
  t != null
  trim(sprintf("%v", [t])) != ""
}

# Determine whether we can confidently enforce diagnostics for this resource.
# If the resource id isn't known AND no diagnostic target appears to reference the TF address,
# skip enforcement (prevents false positives).
can_enforce_for(rc, a) if {
  rid := a.id
  rid != null
  trim(sprintf("%v", [rid])) != ""
}

can_enforce_for(rc, a) if {
  addr := lower(resource_addr(rc))
  some t in all_diag_target_strings
  contains(t, addr)
}

# Enforce: must have at least one diagnostic setting that targets this resource.
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type in resource_types_requiring_diagnostics

  a := tf.after(rc)
  can_enforce_for(rc, a)

  addr := lower(resource_addr(rc))
  rid := lower(sprintf("%v", [a.id]))

  not some t in all_diag_target_strings {
    (rid != ""; t == rid) or (addr != ""; contains(t, addr))
  }

  msg := sprintf("%v '%v' must have an azurerm_monitor_diagnostic_setting (targeting its resource id or referencing its TF address)", [rc.type, tf.resource_name(rc)])
}
