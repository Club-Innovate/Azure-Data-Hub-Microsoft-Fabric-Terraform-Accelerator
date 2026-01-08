package accelerator.logging

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

# Logging / Audit Guardrails
# --------------------------
# Minimal, high-signal rules that align to auditability needs.
#

deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_log_analytics_workspace"

  a := tf.after(rc)

  a.retention_in_days != null
  a.retention_in_days < 30

  msg := sprintf("Log Analytics workspace '%v' retention_in_days=%v must be >= 30", [tf.resource_name(rc), a.retention_in_days])
}
