#
# Space Cloud Foundry + papéis + instâncias de serviço + service keys.
# Ordem garantida: space -> papéis -> instâncias -> keys
# (criar instância exige Space Developer; sem o papel a API responde 403).
#

locals {
  # { space_developer = [a, b] } -> { "space_developer|a" = {...}, "space_developer|b" = {...} }
  role_assignments = merge([
    for role, users in var.roles : {
      for user in users : "${role}|${user}" => {
        role = role
        user = user
      }
    }
  ]...)

  service_keys = merge([
    for key, si in var.service_instances : {
      for consumer in si.keys : "${key}/${consumer}" => {
        instance = key
        consumer = consumer
        offering = si.offering
      }
    }
  ]...)

  # O provider rejeita map vazio; null significa "sem metadados".
  annotations = length(var.annotations) > 0 ? var.annotations : null
}

resource "cloudfoundry_space" "this" {
  name        = var.name
  org         = var.org_id
  allow_ssh   = var.allow_ssh
  labels      = merge(var.labels, { "resource-type" = "cf-space" })
  annotations = local.annotations
}

resource "cloudfoundry_space_role" "this" {
  for_each = local.role_assignments

  space    = cloudfoundry_space.this.id
  type     = each.value.role
  username = each.value.user
  origin   = var.user_origin
}

resource "cloudfoundry_service_instance" "this" {
  for_each = var.service_instances

  name                  = each.value.name
  space                 = cloudfoundry_space.this.id
  type                  = "managed"
  service_offering_name = each.value.offering
  service_plan_name     = each.value.plan
  parameters            = each.value.parameters
  tags                  = length(coalesce(each.value.tags, [])) > 0 ? each.value.tags : null # provider rejeita lista vazia
  annotations           = local.annotations

  labels = merge(var.labels, {
    "resource-type" = "service-instance"
    "service"       = each.value.offering
    "plan"          = each.value.plan
  })

  timeouts = {
    create = "15m"
    delete = "15m"
  }

  depends_on = [cloudfoundry_space_role.this]
}

resource "cloudfoundry_service_credential_binding" "key" {
  for_each = local.service_keys

  type             = "key"
  name             = "sk-${each.value.consumer}"
  service_instance = cloudfoundry_service_instance.this[each.value.instance].id
  annotations      = local.annotations

  labels = merge(var.labels, {
    "resource-type" = "service-key"
    "service"       = each.value.offering
    "consumer"      = each.value.consumer
  })
}
