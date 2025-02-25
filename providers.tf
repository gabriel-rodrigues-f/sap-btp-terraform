terraform {
  required_version = "1.10.5"
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "1.10.0"
    }
    cloudfoundry = {
      source  = "SAP/cloudfoundry"
      version = "1.0.0-rc1"
    }
  }
}

provider "btp" {
  globalaccount = var.global_account_domain
}

provider "cloudfoundry" {
  api_url  = var.cloud_foundry_api
  user     = var.cloud_foundry_user
  password = var.cloud_foundry_password
}
