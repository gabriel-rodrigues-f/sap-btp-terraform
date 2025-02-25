terraform {
  required_version = "1.10.5"
  required_providers {
    cloudfoundry = {
      source  = "SAP/cloudfoundry"
      version = "1.0.0-rc1"
    }
  }
}
