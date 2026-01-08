package accelerator.tfplan

import rego.v1
import future.keywords.in
# Shared helpers for parsing Terraform plan JSON
# Allowed Azure regions baseline (customize as needed).

# Terraform Plan Policy Pack (OPA/Rego v1 + Conftest)
# ===================================================
# Input expected:
#   terraform plan -out=tfplan
#   terraform show -json tfplan > plan.json
#   conftest test --policy policy/ plan.json
#
# This file provides shared helpers + common policy data used by the other .rego files.
#

# -----------------------------
# Policy configuration (edit me)
# -----------------------------

# Approved Azure regions baseline (customize per organization).
approved_regions := {
  "eastus",
  "eastus2",
  "centralus",
  "westus",
  "westus2",
}

# Required tags for governed Azure resources.
required_tags := {
  "owner",
  "environment",
  "project",
  "data_classification",
}

# -----------------------------
# Helper functions
# -----------------------------

# Returns true if this resource change includes create or update.
is_create_or_update(rc) if {
  some a in rc.change.actions
  a == "create" or a == "update"
}

# Returns true if this is a managed resource change we should evaluate.
is_managed_change(rc) if {
  rc.mode == "managed"
  is_create_or_update(rc)
  rc.change.after != null
}

# List of managed resource changes (create/update) with an "after" state.
managed_changes := [rc |
  rc := input.resource_changes[_]
  is_managed_change(rc)
]

# Safe lookup: return the resource "after" object.
after(rc) := rc.change.after

# Safe lookup: normalize a location string if present; otherwise empty.
location(after_obj) := lower(after_obj.location) if {
  after_obj.location != null
} else := "" if {
  true
}

# Safe lookup: tags map or empty object
tags(after_obj) := after_obj.tags if {
  after_obj.tags != null
} else := {} if {
  true
}

# Safe lookup: resource name from the "after" object if present; otherwise Terraform name.
resource_name(rc) := after(rc).name if {
  after(rc).name != null
} else := rc.name if {
  true
}

# Returns an array of missing keys.
missing_keys(m, keys) := [k |
  k := keys[_]
  m[k] == null
]

# Basic Azure name rule: lowercase letters/numbers/hyphen.
is_kebab_lower(s) if {
  regex.match("^[a-z0-9-]+$", s)
}

# Storage account naming: lowercase letters/numbers only, 3-24 chars.
is_storage_name(s) if {
  regex.match("^[a-z0-9]{3,24}$", s)
}
