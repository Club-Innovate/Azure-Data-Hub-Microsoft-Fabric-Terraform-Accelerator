#############################################
# infra/variables.tf
#############################################

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID."
}

variable "client_id" {
  type        = string
  description = "Service principal client ID."
}

variable "client_secret" {
  type        = string
  description = "Service principal client secret."
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus"
}

variable "prefix" {
  type        = string
  description = "Resource naming prefix (lowercase, alphanumeric)."
  default     = "avatar"
}

variable "environment" {
  type        = string
  description = "Environment name, e.g. 'dev', 'qa', 'prod'."
  default     = "dev"
}

variable "company_name" {
  type        = string
  description = "Company name used in descriptions and display names."
  default     = "avatar"
}

variable "project_name" {
  type        = string
  description = "Project name used in tags and descriptions."
  default     = "Data-Hub"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default = {
    project     = "avatar-Data-Hub"
    managed-by  = "terraform"
    environment = "dev"
  }
}

variable "enable_fabric" {
  type        = bool
  description = "Whether to deploy Fabric capacity."
  default     = true
}

variable "fabric_capacity_name" {
  type        = string
  description = "ARM resource name AND Fabric display name for the capacity. Must be alphanumeric."
  default     = "" # Will be constructed from prefix + environment if not provided
}

variable "fabric_sku_name" {
  type        = string
  description = "Fabric capacity SKU (e.g. F2, F4, F8, F64, F128)."
  default     = "F64"
}

variable "fabric_admin_object_ids" {
  description = "Object IDs of Entra users or service principals that will be Fabric capacity admins. Groups are NOT supported."
  type        = list(string)
  default     = []
}

variable "fabric_admin_upns" {
  type        = list(string)
  description = "UPNs for Fabric admins to be added as workspace admins."
  default     = []
}

variable "fabric_admin_principals" {
  description = "(Optional) Object IDs of Entra users or service principals that will be Fabric capacity admins. Prefer this variable over fabric_admin_object_ids."
  type        = list(string)
  default     = []
}

variable "fabric_admin_principal_object_ids" {
  description = "List of Entra ID OBJECT IDs for Fabric capacity admins. Must be USER or SERVICE PRINCIPAL object IDs (groups are NOT supported by Fabric capacity ARM)."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for x in var.fabric_admin_principal_object_ids : can(regex("^[0-9a-fA-F-]{36}$", x))])
    error_message = "fabric_admin_principal_object_ids must contain valid GUIDs (Entra ID object IDs)."
  }
}

variable "log_analytics_retention_days" {
  type        = number
  description = "Log Analytics retention (days)."
  default     = 30
}

variable "enable_storage_medallion" {
  type        = bool
  description = "Deploy the Storage Medallion resources."
  default     = true
}

variable "enable_api_management" {
  type        = bool
  description = "Deploy API Management."
  default     = true
}

variable "enable_key_vault" {
  description = "Enable or disable Key Vault module"
  type        = bool
  default     = true
}

variable "enable_log_analytics" {
  description = "Enable or disable Log Analytics module"
  type        = bool
  default     = true
}

variable "enable_networking" {
  description = "Enable or disable Networking module"
  type        = bool
  default     = true
}

variable "enable_purview" {
  description = "Enable or disable Purview module"
  type        = bool
  default     = true
}

variable "enable_data_factory" {
  description = "Enable or disable Data Factory module"
  type        = bool
  default     = true
}

#############################################
# Compliance Policy Variables
#############################################

variable "enable_hipaa" {
  type        = bool
  description = "Enable HIPAA/HITECH compliance policy enforcement."
  default     = false
}

variable "enable_gdpr" {
  type        = bool
  description = "Enable GDPR compliance policy enforcement."
  default     = false
}

variable "compliance_scope" {
  type        = string
  description = "Scope for compliance policy assignment: 'resource_group' or 'resource'."
  default     = "resource_group"
  validation {
    condition     = contains(["resource_group", "resource"], var.compliance_scope)
    error_message = "compliance_scope must be 'resource_group' or 'resource'."
  }
}
