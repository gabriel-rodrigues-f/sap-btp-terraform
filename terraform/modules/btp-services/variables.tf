variable "subaccount_id" {
  description = "ID do subaccount (use o output do módulo btp-subaccount, que já espera os entitlements)."
  type        = string
}

variable "labels" {
  description = "Labels de FinOps (map de set). Máximo 9 chaves: a service key soma 'consumer' e o BTP aceita 10."
  type        = map(set(string))
  default     = {}

  validation {
    condition     = length(var.labels) <= 9
    error_message = "Use no máximo 9 chaves: a service key adiciona 'consumer' e o BTP aceita 10."
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

variable "label_service_manager_resources" {
  description = <<-EOT
    Aplica as labels também nas instâncias e service keys do Service Manager.
    Desligado por padrão: no provider SAP/btp 1.27.0, a criação dessas
    instâncias grava a ÚLTIMA chave de label com uma aspa extra
    (ex.: workload = application-integration") e o apply falha com
    "Provider produced inconsistent result after apply". Directory e
    subaccount não são afetados. Religue quando o provider corrigir.
  EOT
  type        = bool
  default     = false
}
