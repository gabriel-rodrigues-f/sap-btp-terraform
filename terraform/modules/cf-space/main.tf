#
# Space Cloud Foundry + papéis + instâncias de serviço.
# É a "fronteira" entre plataforma (Terraform) e workload (Ansible):
# o Ansible faz o deploy da aplicação neste space e a liga a estes serviços.
#

locals {
  # O provider rejeita map vazio em `labels`; null significa "sem labels".
  labels = length(var.labels) > 0 ? var.labels : null

  # { space_developer = [a, b] } -> { "space_developer|a" = {...}, "space_developer|b" = {...} }
  role_assignments = merge([
    for role, users in var.roles : {
      for user in users : "${role}|${user}" => {
        role = role
        user = user
      }
    }
  ]...)
}

resource "cloudfoundry_space" "this" {
  name      = var.name
  org       = var.org_id
  allow_ssh = var.allow_ssh
  labels    = local.labels
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

  name                  = each.key
  space                 = cloudfoundry_space.this.id
  type                  = "managed"
  service_offering_name = each.value.offering
  service_plan_name     = each.value.plan
  parameters            = each.value.parameters
  tags                  = length(coalesce(each.value.tags, [])) > 0 ? each.value.tags : null # provider rejeita lista vazia
  labels                = local.labels

  timeouts = {
    create = "15m"
    delete = "15m"
  }
}
