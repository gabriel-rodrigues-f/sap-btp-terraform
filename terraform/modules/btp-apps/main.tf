#
# Assinaturas SaaS + role collections de cada uma, atribuídas a usuários do IAS.
#
# A role collection só existe DEPOIS da assinatura. Em vez de um depends_on
# genérico (que esperaria TODAS as assinaturas), cada atribuição referencia o
# atributo da SUA assinatura: o Terraform cria a role do BAS assim que o BAS
# fica pronto, sem esperar o Integration Suite, por exemplo.
#

locals {
  role_assignments = merge([
    for key, sub in var.subscriptions : {
      for pair in setproduct(sub.role_collections, var.users) : "${key}|${pair[0]}|${pair[1]}" => {
        subscription    = key
        role_collection = pair[0]
        user            = pair[1]
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

resource "btp_subaccount_role_collection_assignment" "this" {
  for_each = local.role_assignments

  # Referência à assinatura específica = dependência só dela.
  subaccount_id        = btp_subaccount_subscription.this[each.value.subscription].subaccount_id
  role_collection_name = each.value.role_collection
  user_name            = each.value.user
  origin               = var.origin
}
