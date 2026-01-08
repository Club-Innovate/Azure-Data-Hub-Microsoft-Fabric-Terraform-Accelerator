variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "client_id" {
  type        = string
  description = "Service principal client ID used for Fabric provider."
}

variable "client_secret" {
  type        = string
  description = "Service principal client secret used for Fabric provider."
  sensitive   = true
}

variable "fabric_capacity_name" {
  type        = string
  description = "Display name of the Fabric capacity as seen in Fabric. Must match infra.fabric_capacity_name."
  default     = "" # Will be constructed from prefix + environment if not provided
}

variable "fabric_workspace_display_name" {
  type        = string
  description = "Display name for the primary Fabric workspace."
  default     = "" # Will be constructed from company_name + environment if not provided
}

variable "prefix" {
  type        = string
  description = "Name prefix used for lakehouse, etc."
  default     = "avatar"
}

variable "environment" {
  type        = string
  description = "Environment for naming, e.g. dev/qa/prod."
  default     = "dev"
}

variable "company_name" {
  type        = string
  description = "Company name used in workspace display names and descriptions."
  default     = "avatar"
}

variable "enable_fabric_lakehouse" {
  type        = bool
  description = "Whether to create the Fabric lakehouse."
  default     = true
}

variable "fabric_admin_upns" {
  type        = list(string)
  description = "UPNs for Fabric admins to be added as workspace admins."
  default     = []
}

variable "fabric_admin_object_ids" {
  description = "Object IDs of Entra users or service principals that will be Fabric capacity admins. Groups are NOT supported."
  type        = list(string)
  default     = []
}

variable "enable_key_vault" {
  description = "Enable or disable Key Vault module"
  type        = bool
  default     = true
}

variable "enable_networking" {
  description = "Enable or disable Networking module"
  type        = bool
  default     = true
}

variable "enable_log_analytics" {
  description = "Enable or disable Log Analytics module"
  type        = bool
  default     = true
}

variable "enable_storage_medallion" {
  description = "Deploy the Storage Medallion resources."
  type        = bool
  default     = true
}

variable "enable_purview" {
  description = "Enable or disable Purview module"
  type        = bool
  default     = true
}

variable "enable_fabric" {
  type        = bool
  description = "Whether to deploy Fabric capacity."
  default     = true
}

variable "enable_data_factory" {
  description = "Enable or disable Data Factory module"
  type        = bool
  default     = true
}

variable "enable_api_management" {
  description = "Deploy API Management."
  type        = bool
  default     = false
}

variable "fabric_sku_name" {
  type        = string
  description = "Fabric capacity SKU (e.g. F2, F4, F8, F64, F128)."
  default     = "F64"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "westus"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}

variable "project_name" {
  type        = string
  description = "Project name used for tags and descriptions."
  default     = ""
}