variable "subaccount_id" {
  description = "ID do subaccount (use o output do módulo btp-subaccount, que já espera os entitlements)."
  type        = string
}

variable "labels" {
  description = "Labels de FinOps (map de set) aplicadas a instâncias e service keys."
  type        = map(set(string))
  default     = {}
}

variable "subscriptions" {
  description = <<-EOT
    Assinaturas de aplicações SaaS. Use o NOME TÉCNICO da app (btp list
    accounts/subscription), que pode diferir do nome do entitlement.
    'parameters' é uma string JSON.
  EOT
  type = list(object({
    app_name   = string
    plan_name  = string
    parameters = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.subscriptions : s.parameters == null || can(jsondecode(s.parameters))])
    error_message = "subscriptions[*].parameters deve ser um JSON válido."
  }
}

variable "service_instances" {
  description = <<-EOT
    Instâncias no nível do SUBACCOUNT (Service Manager, ambiente "Other"),
    independentes de Cloud Foundry/Kyma. A chave é lógica; o nome vem pronto
    do módulo naming. 'keys' lista os consumidores que recebem uma service key.
  EOT
  type = map(object({
    name       = string
    offering   = string
    plan       = string
    parameters = optional(string)
    keys       = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for si in values(var.service_instances) : si.parameters == null || can(jsondecode(si.parameters))])
    error_message = "service_instances[*].parameters deve ser um JSON válido."
  }

  validation {
    condition = alltrue(flatten([
      for si in values(var.service_instances) : [for c in si.keys : can(regex("^[a-z0-9][a-z0-9-]{0,40}[a-z0-9]$", c))]
    ]))
    error_message = "Consumidores de service key: kebab-case curto (ex.: cicd, integration-suite)."
  }
}
