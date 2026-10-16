terraform {
  # Módulos declaram apenas o MÍNIMO que precisam (">="). Quem fixa a versão
  # exata é o root module (stack), via .terraform.lock.hcl.
  required_version = ">= 1.9.0"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = ">= 1.27.0"
    }
  }
}
