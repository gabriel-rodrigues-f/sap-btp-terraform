terraform {
  # POC: estado LOCAL (arquivo terraform.tfstate nesta pasta, fora do git).
  #
  # Em time/produção use um backend remoto com criptografia e LOCK, por exemplo:
  #
  #   backend "s3" {                       # AWS S3 (lock nativo com use_lockfile)
  #     bucket       = "minha-empresa-tfstate"
  #     key          = "btp/corporate-it/application-integration-qa-us10/15-btp-services.tfstate"
  #     region       = "us-east-1"
  #     use_lockfile = true
  #     encrypt      = true
  #   }
  #
  #   backend "azurerm" { ... }            # Azure Storage (lock via blob lease)
  #   cloud { organization = "..." }       # HCP Terraform
  #
  # O estado contém dados sensíveis (IDs, às vezes segredos). Nunca o versione.
  backend "local" {
    path = "terraform.tfstate"
  }
}
