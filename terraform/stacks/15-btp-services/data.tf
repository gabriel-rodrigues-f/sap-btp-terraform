# Lê os OUTPUTS do stack 10 (subaccount, convenções, labels, personas).
data "terraform_remote_state" "account" {
  backend = "local"

  config = {
    path = "${path.root}/../10-btp-account/terraform.tfstate"
  }
}

locals {
  account = data.terraform_remote_state.account.outputs
}
