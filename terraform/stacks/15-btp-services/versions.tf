terraform {
  # Root modules fixam a faixa de versões; o .terraform.lock.hcl (versionado!)
  # garante que todo mundo use exatamente o mesmo binário de provider.
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.27" # aceita 1.27.x, 1.28... mas nunca 2.0 (breaking changes)
    }
  }
}
