package accelerator.storage

import rego.v1
import future.keywords.in
import data.accelerator.tfplan as tf

# Storage Account Guardrails
# --------------------------
# High-signal baseline controls for data platform storage.
#

# HTTPS traffic only
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_storage_account"

  a := tf.after(rc)

  a.enable_https_traffic_only != true

  msg := sprintf("Storage account '%v' must set enable_https_traffic_only = true", [tf.resource_name(rc)])
}

# Enforce TLS 1.2+
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_storage_account"

  a := tf.after(rc)

  v := lower(sprintf("%v", [a.min_tls_version]))

  # If unset, Azure defaults vary by API/provider version; require explicit TLS baseline.
  (a.min_tls_version == null) or not (v == "tls1_2" or v == "tls1_3")

  msg := sprintf("Storage account '%v' must set min_tls_version to TLS1_2 (or higher)", [tf.resource_name(rc)])
}

# Disable blob public access
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_storage_account"

  a := tf.after(rc)

  a.allow_blob_public_access != false

  msg := sprintf("Storage account '%v' must set allow_blob_public_access = false", [tf.resource_name(rc)])
}

# Prevent anonymous public network access (baseline). If you intentionally allow, add an exception tag.
# Exception mechanism: tag `public_network_access_exception = "true"`
deny contains msg if {
  rc := tf.managed_changes[_]
  rc.type == "azurerm_storage_account"

  a := tf.after(rc)
  t := tf.tags(a)

  exc := lower(sprintf("%v", [t.public_network_access_exception]))
  exc != "true"

  a.public_network_access_enabled != false

  msg := sprintf("Storage account '%v' must set public_network_access_enabled = false (or set tag public_network_access_exception=true)", [tf.resource_name(rc)])
}
