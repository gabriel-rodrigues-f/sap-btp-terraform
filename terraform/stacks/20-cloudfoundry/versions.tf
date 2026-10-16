terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    # O provider oficial hoje é mantido pela Cloud Foundry Foundation.
    # "SAP/cloudfoundry" (1.0.0-rc1) foi o nome antigo e está abandonado.
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "~> 1.18"
    }
  }
}
