# Lê os OUTPUTS do stack 10 (e só eles). Assim o contrato entre camadas é
# explícito e versionado em ../10-btp-subaccount/outputs.tf.
#
# Com backend remoto, troque backend/config pelo mesmo backend do stack 10
# (ex.: backend = "s3" + bucket/key). Alternativa com menos acoplamento:
# receber os valores por variável (TF_VAR_cf_org_id=...) a partir do pipeline.
data "terraform_remote_state" "account" {
  backend = "local"

  config = {
    path = "${path.root}/../10-btp-subaccount/terraform.tfstate"
  }
}

locals {
  account = data.terraform_remote_state.account.outputs
}
