variable "org_id" {
  description = "GUID da org (use o output do cf-org-access, que já espera os papéis de org)."
  type        = string
}

variable "name" {
  description = "Nome do space (finalidade dentro da org, ex.: integration)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.name))
    error_message = "Nome do space em kebab-case minúsculo."
  }
}

variable "allow_ssh" {
  description = "Permite `cf ssh` nos containers. Desligado por padrão (menor superfície de ataque)."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels de FinOps no formato do Cloud Foundry (map de string)."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Annotations do Cloud Foundry (dados que não cabem em label: e-mail, URL)."
  type        = map(string)
  default     = {}
}

variable "roles" {
  description = <<-EOT
    Usuários por papel no space. Papéis válidos: space_manager, space_developer,
    space_auditor, space_supporter. O usuário precisa ser membro da org antes.
  EOT
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for role in keys(var.roles) :
      contains(["space_manager", "space_developer", "space_auditor", "space_supporter"], role)
    ])
    error_message = "Papel inválido. Use space_manager, space_developer, space_auditor ou space_supporter."
  }
}

variable "user_origin" {
  description = "Origem (IdP) dos usuários no UAA do Cloud Foundry. sap.ids = SAP ID service."
  type        = string
  default     = "sap.ids"
}

variable "service_instances" {
  description = <<-EOT
    Instâncias gerenciadas no space (chave lógica => definição). O nome vem
    pronto do módulo naming. 'parameters' é uma string JSON. 'keys' lista os
    consumidores que recebem uma service key (sk-<consumidor>).
  EOT
  type = map(object({
    name       = string
    offering   = string
    plan       = string
    parameters = optional(string)
    tags       = optional(list(string))
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
