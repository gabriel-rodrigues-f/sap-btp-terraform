terraform {
  required_version = ">= 1.9.0"

  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = ">= 1.18.0"
    }
  }
}
