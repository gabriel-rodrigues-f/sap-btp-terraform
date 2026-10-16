#
# Directory = "management group" do CAF: agrupa os subaccounts de uma unidade
# de negócio, concentra a cota (ENTITLEMENTS) e as permissões (AUTHORIZATIONS),
# e soma o custo da área num único lugar.
#

locals {
  entitlements = {
    for e in var.entitlements : "${e.service_name}/${e.plan_name}" => e
  }

  role_collection_assignments = merge([
    for role_collection, users in var.role_collection_assignments : {
      for user in users : "${role_collection}|${user}" => {
        role_collection = role_collection
        user            = user
      }
    }
  ]...)
}

resource "btp_directory" "this" {
  name        = var.name
  description = var.description
  subdomain   = var.subdomain
  labels      = var.labels

  # DEFAULT: agrupar e ver custo | ENTITLEMENTS: distribuir cota |
  # AUTHORIZATIONS: ter administradores/viewers próprios (exige ENTITLEMENTS).
  features = ["DEFAULT", "ENTITLEMENTS", "AUTHORIZATIONS"]
}

resource "btp_directory_entitlement" "this" {
  for_each = local.entitlements

  directory_id = btp_directory.this.id
  service_name = each.value.service_name
  plan_name    = each.value.plan_name
  amount       = each.value.amount
}

resource "btp_directory_role_collection_assignment" "this" {
  for_each = local.role_collection_assignments

  directory_id         = btp_directory.this.id
  role_collection_name = each.value.role_collection
  user_name            = each.value.user
}
