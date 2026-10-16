#
# Assinaturas SaaS + role collections de cada uma, atribuídas a usuários do IAS.
#
# A role collection só existe DEPOIS da assinatura. Em vez de um depends_on
# genérico (que esperaria TODAS as assinaturas), cada atribuição referencia o
# atributo da SUA assinatura: o Terraform cria a role do BAS assim que o BAS
# fica pronto, sem esperar o Integration Suite, por exemplo.
#

locals {
  custom_role_collections = merge([
    for key, sub in var.subscriptions : {
      for name, rc in sub.custom_role_collections : name => merge(rc, { subscription = key })
    }
  ]...)

  # Atribui as role collections nativas E as customizadas de cada app.
  role_assignments = merge([
    for key, sub in var.subscriptions : {
      for pair in setproduct(concat(sub.role_collections, keys(sub.custom_role_collections)), var.users) : "${key}|${pair[0]}|${pair[1]}" => {
        subscription    = key
        role_collection = pair[0]
        user            = pair[1]
        custom          = contains(keys(sub.custom_role_collections), pair[0])
      }
    }
  ]...)
}

resource "btp_subaccount_subscription" "this" {
  for_each = var.subscriptions

  subaccount_id = var.subaccount_id
  app_name      = each.value.app_name
  plan_name     = each.value.plan
  parameters    = each.value.parameters

  timeouts = {
    create = "45m"
    delete = "45m"
  }
}

# Roles disponíveis no subaccount: só existem depois das assinaturas.
data "btp_subaccount_roles" "all" {
  count = length(local.custom_role_collections) > 0 ? 1 : 0

  subaccount_id = var.subaccount_id
  depends_on    = [btp_subaccount_subscription.this]
}

resource "btp_subaccount_role_collection" "custom" {
  for_each = local.custom_role_collections

  subaccount_id = btp_subaccount_subscription.this[each.value.subscription].subaccount_id
  name          = each.key
  description   = "Criada por Terraform para a assinatura ${each.value.subscription}"

  # O app id tem sufixo do landscape (ex.: appgyver-xsuaa!b107153): casamos por prefixo.
  roles = [
    for role in data.btp_subaccount_roles.all[0].values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    }
    if contains(each.value.role_templates, role.role_template_name)
    && anytrue([for prefix in each.value.app_prefixes : startswith(role.app_id, prefix)])
  ]
}

resource "btp_subaccount_role_collection_assignment" "this" {
  for_each = local.role_assignments

  # Referência à assinatura específica = dependência só dela.
  subaccount_id = btp_subaccount_subscription.this[each.value.subscription].subaccount_id
  # Role collection customizada: referencia o recurso para esperar a criação.
  role_collection_name = each.value.custom ? btp_subaccount_role_collection.custom[each.value.role_collection].name : each.value.role_collection
  user_name            = each.value.user
  origin               = var.origin
}
