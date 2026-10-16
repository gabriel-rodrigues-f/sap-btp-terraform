terraform {
  required_version = ">= 1.9.0"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = ">= 1.27.0"
    }
  }
}
