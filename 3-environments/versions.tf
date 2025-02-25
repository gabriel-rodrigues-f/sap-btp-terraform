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
