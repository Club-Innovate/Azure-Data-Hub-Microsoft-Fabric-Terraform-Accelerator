terraform {
  required_version = ">= 1.3.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = ">= 0.1.0-rc.2"
    }
  }
}

provider "fabric" {
  #client_id     = var.client_id
  #client_secret = var.client_secret
  #tenant_id     = var.tenant_id
}
