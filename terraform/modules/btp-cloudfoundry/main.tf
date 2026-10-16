#
# Habilita o ambiente Cloud Foundry (= cria a org) num subaccount.
# Tudo DENTRO da org (spaces, roles, serviços) é responsabilidade do provider
# cloudfoundry, em outro stack. Veja docs/04-terraform-boas-praticas.md.
#

resource "btp_subaccount_environment_instance" "this" {
  subaccount_id    = var.subaccount_id
  name             = var.org_name
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = var.plan_name
  landscape_label  = var.landscape_label

  parameters = jsonencode({
    instance_name = var.org_name
  })

  timeouts = {
    create = var.create_timeout
    update = "30m"
    delete = "30m"
  }
}

locals {
  # O broker devolve os dados da org num JSON em texto (atributo `labels`), ex.:
  # {"API Endpoint":"https://api.cf.us10-001.hana.ondemand.com","Org Name":"...","Org ID":"..."}
  # try() evita que um formato inesperado quebre o plan inteiro.
  environment_labels = try(jsondecode(btp_subaccount_environment_instance.this.labels), {})
}
