variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

variable "publisher_name" {
  type        = string
  description = "Publisher name for API Management."
  default     = "avatar"
}

variable "publisher_email" {
  type        = string
  description = "Publisher email for API Management."
  default     = "admin@example.com"
}

resource "azurerm_api_management" "this" {
  name                = "${var.prefix}-${var.environment}-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  sku_name = "Developer_1"

  tags = var.tags
}

output "gateway_url" {
  value = azurerm_api_management.this.gateway_url
}
