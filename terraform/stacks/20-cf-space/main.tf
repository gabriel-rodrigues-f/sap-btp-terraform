#
# Stack 20 - camada de PLATAFORMA Cloud Foundry (provider cloudfoundry/cloudfoundry)
#
#   org (do stack 10) -> space + papéis + instâncias de serviço
#
# A aplicação em si NÃO é criada aqui: deploy é responsabilidade do Ansible.
#

locals {
  space_roles = length(var.space_roles) > 0 ? var.space_roles : {
    space_manager   = local.account.admins
    space_developer = local.account.admins
  }
}

module "space" {
  source = "../../modules/cf-space"

  org_id            = local.account.cf_org_id
  name              = var.space_name
  roles             = local.space_roles
  service_instances = var.service_instances

  # Labels do Cloud Foundry são map(string) (diferente do BTP, que é map(set)).
  labels = {
    "managed-by" = "terraform"
    "project"    = local.account.project
    "stage"      = local.account.stage
  }
}
