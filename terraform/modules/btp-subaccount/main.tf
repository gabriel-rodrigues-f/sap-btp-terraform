#
# Subaccount = "resource group" do CAF: a fronteira de um workload num ambiente
# e região. Nasce com nome padronizado, labels de FinOps, cota e permissões.
#   subaccount -> entitlements -> role collections
# (Serviços, assinaturas e service keys ficam no módulo btp-services.)
#

locals {
  # for_each precisa de MAPAS com chaves estáveis. Derivar a chave de atributos
  # de negócio (e não do índice da lista) evita que reordenar a lista recrie recursos.
  entitlements = {
    for e in var.entitlements : "${e.service_name}/${e.plan_name}" => e
  }

  # Achata { role_collection = [users] } em { "role_collection|user" = {...} }
  role_collection_assignments = merge([
    for role_collection, users in var.role_collection_assignments : {
      for user in users : "${role_collection}|${user}" => {
        role_collection = role_collection
        user            = user
      }
    }
  ]...)
}

resource "btp_subaccount" "this" {
  name        = var.name
  subdomain   = var.subdomain
  region      = var.region
  description = var.description
  parent_id   = var.parent_id
  usage       = var.usage
  labels      = var.labels

  # Em produção, considere `lifecycle { prevent_destroy = true }`: o subaccount
  # guarda apps, serviços e dados, e um destroy acidental é irrecuperável.
  # Não usamos aqui porque a POC precisa de `make down`, e prevent_destroy não
  # aceita variável (é avaliado antes de qualquer expressão).
}

resource "btp_subaccount_entitlement" "this" {
  for_each = local.entitlements

  subaccount_id = btp_subaccount.this.id
  service_name  = each.value.service_name
  plan_name     = each.value.plan_name
  amount        = each.value.amount
}

resource "btp_subaccount_role_collection_assignment" "this" {
  for_each = local.role_collection_assignments

  subaccount_id        = btp_subaccount.this.id
  role_collection_name = each.value.role_collection
  user_name            = each.value.user
}
