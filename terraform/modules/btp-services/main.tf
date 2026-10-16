#
# Serviços consumidos no nível do SUBACCOUNT:
#   - assinaturas SaaS (aplicações multitenant da SAP)
#   - instâncias via Service Manager (ambiente "Other": servem a qualquer
#     runtime ou a sistemas externos, como Integration Suite e pipelines)
#   - service keys (bindings) por CONSUMIDOR, cada uma rastreável por label
#

locals {
  subscriptions = {
    for s in var.subscriptions : "${s.app_name}/${s.plan_name}" => s
  }

  # Uma service key por consumidor: rotacionar ou revogar o acesso de um
  # consumidor não afeta os outros, e o custo/uso fica atribuível.
  service_keys = merge([
    for key, si in var.service_instances : {
      for consumer in si.keys : "${key}/${consumer}" => {
        instance = key
        consumer = consumer
        offering = si.offering
      }
    }
  ]...)
}

resource "btp_subaccount_subscription" "this" {
  for_each = local.subscriptions

  subaccount_id = var.subaccount_id
  app_name      = each.value.app_name
  plan_name     = each.value.plan_name
  parameters    = each.value.parameters

  # Assinaturas NÃO aceitam labels na API do BTP. O custo delas é atribuído
  # pelas labels do subaccount (veja docs/03-governanca.md).
  timeouts = {
    create = "30m"
    delete = "30m"
  }
}

resource "btp_subaccount_service_instance" "this" {
  for_each = var.service_instances

  subaccount_id         = var.subaccount_id
  name                  = each.value.name
  service_offering_name = each.value.offering
  serviceplan_name      = each.value.plan
  parameters            = each.value.parameters

  labels = merge(var.labels, {
    "resource-type" = toset(["service-instance"])
    "service"       = toset([each.value.offering])
    "plan"          = toset([each.value.plan])
  })

  timeouts = {
    create = "20m"
    delete = "20m"
  }
}

resource "btp_subaccount_service_binding" "this" {
  for_each = local.service_keys

  subaccount_id       = var.subaccount_id
  service_instance_id = btp_subaccount_service_instance.this[each.value.instance].id
  name                = "sk-${each.value.consumer}"

  labels = merge(var.labels, {
    "resource-type" = toset(["service-key"])
    "service"       = toset([each.value.offering])
    "consumer"      = toset([each.value.consumer])
  })
}
