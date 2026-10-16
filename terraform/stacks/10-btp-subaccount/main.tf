#
# Stack 10 - camada de CONTA (provider SAP/btp)
#
#   [directory opcional] -> subaccount + entitlements + destinations + admins
#                        -> ambiente Cloud Foundry (org)
#
# O que vive DENTRO da org (space, papéis, serviços) fica no stack 20, porque o
# provider cloudfoundry precisa do endpoint da API que só existe depois deste apply.
#

locals {
  # "1a2b3c4dtrial-ga" -> "1a2b3c4dtrial": prefixo único do seu global account.
  # Subdomínio do subaccount e nome da org precisam ser únicos NA REGIÃO
  # (entre todos os clientes SAP), então reaproveitamos essa unicidade.
  globalaccount_prefix = trimsuffix(var.globalaccount, "-ga")
  name_prefix          = "${local.globalaccount_prefix}-${var.project}-${var.stage}"

  # Labels padronizadas permitem filtrar no cockpit e em relatórios de custo.
  # Nada de timestamp() aqui: valor que muda a cada plan = diff eterno (drift falso).
  labels = merge(var.labels, {
    "managed-by" = ["terraform"]
    "project"    = [var.project]
    "stage"      = [var.stage]
  })
}

resource "btp_directory" "this" {
  count = var.directory_name == null ? 0 : 1

  name        = var.directory_name
  description = "Agrupa os subaccounts do projeto ${var.project}"
  labels      = local.labels
}

module "subaccount" {
  source = "../../modules/btp-subaccount"

  name        = "${var.project}-${var.stage}"
  subdomain   = local.name_prefix
  region      = var.region
  description = "Subaccount ${var.stage} do projeto ${var.project} (gerenciado por Terraform)"
  parent_id   = one(btp_directory.this[*].id)
  labels      = local.labels

  entitlements  = var.entitlements
  subscriptions = var.subscriptions
  destinations  = var.destinations

  role_collection_assignments = {
    for role_collection in var.admin_role_collections : role_collection => var.admins
  }
}

module "cloudfoundry" {
  source = "../../modules/btp-cloudfoundry"

  # module.subaccount.id só "fica pronto" após os entitlements (veja o output
  # no módulo), então a org só é criada quando a cota de memória já existe.
  subaccount_id = module.subaccount.id
  org_name      = local.name_prefix
  plan_name     = var.cf_environment_plan
}
