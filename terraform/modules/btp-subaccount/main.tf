#
# "Subaccount baseline": tudo o que um subaccount precisa para nascer pronto.
# subaccount -> entitlements -> (assinaturas, destinations) + role collections
#

locals {
  # for_each precisa de MAPAS com chaves estáveis. Derivar a chave de atributos
  # de negócio (e não do índice da lista) evita que reordenar a lista recrie recursos.
  entitlements = {
    for e in var.entitlements : "${e.service_name}/${e.plan_name}" => e
  }

  subscriptions = {
    for s in var.subscriptions : "${s.app_name}/${s.plan_name}" => s
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

resource "btp_subaccount_subscription" "this" {
  for_each = local.subscriptions

  subaccount_id = btp_subaccount.this.id
  app_name      = each.value.app_name
  plan_name     = each.value.plan_name
  parameters    = each.value.parameters

  # Dependência explícita: a assinatura falha se o entitlement ainda não existir,
  # e não há referência de atributo que o Terraform possa inferir.
  depends_on = [btp_subaccount_entitlement.this]
}

resource "btp_subaccount_role_collection_assignment" "this" {
  for_each = local.role_collection_assignments

  subaccount_id        = btp_subaccount.this.id
  role_collection_name = each.value.role_collection
  user_name            = each.value.user
}

resource "btp_subaccount_destination_generic" "this" {
  for_each = var.destinations

  subaccount_id = btp_subaccount.this.id

  # O recurso "generic" aceita qualquer tipo de destination (HTTP, RFC, LDAP,
  # MAIL...) como um JSON com as mesmas chaves que você vê no cockpit.
  destination_configuration = jsonencode(merge(
    {
      Name           = each.key
      Type           = "HTTP"
      URL            = each.value.url
      ProxyType      = each.value.proxy_type
      Authentication = each.value.authentication
    },
    each.value.description == null ? {} : { Description = each.value.description },
    each.value.properties,
  ))

  depends_on = [btp_subaccount_entitlement.this]
}
