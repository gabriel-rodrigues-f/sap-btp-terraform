variable "name" {
  description = "Nome de exibição do subaccount (ex.: application-integration-qa-us10)."
  type        = string
}

variable "subdomain" {
  description = "Subdomínio do subaccount. Único por região e IMUTÁVEL (alterar recria o subaccount)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.subdomain))
    error_message = "O subdomínio deve ter 3-63 caracteres: letras minúsculas, números e hífen (sem começar/terminar com hífen)."
  }
}

variable "region" {
  description = "Região do subaccount (ex.: us10 ou ap21 na trial)."
  type        = string
}

variable "description" {
  description = "Descrição do subaccount."
  type        = string
  default     = null
}

variable "parent_id" {
  description = "ID do directory pai. null = subaccount direto no global account."
  type        = string
  default     = null
}

variable "usage" {
  description = "Flag de produção do subaccount: UNSET, NOT_USED_FOR_PRODUCTION ou USED_FOR_PRODUCTION."
  type        = string
  default     = "NOT_USED_FOR_PRODUCTION"

  validation {
    condition     = contains(["UNSET", "NOT_USED_FOR_PRODUCTION", "USED_FOR_PRODUCTION"], var.usage)
    error_message = "usage deve ser UNSET, NOT_USED_FOR_PRODUCTION ou USED_FOR_PRODUCTION."
  }
}

variable "labels" {
  description = "Labels de FinOps do subaccount (map de set, formato da API do BTP)."
  type        = map(set(string))
  default     = {}
}

variable "entitlements" {
  description = <<-EOT
    Entitlements atribuídos ao subaccount. A chave interna do for_each é
    "service_name/plan_name", então a ordem da lista não importa.
    'amount' só vale para planos com cota numérica (ex.: APPLICATION_RUNTIME/MEMORY).
  EOT
  type = list(object({
    service_name = string
    plan_name    = string
    amount       = optional(number)
  }))
  default = []

  validation {
    condition = length(var.entitlements) == length(distinct([
      for e in var.entitlements : "${e.service_name}/${e.plan_name}"
    ]))
    error_message = "Há entitlements duplicados (mesmo service_name/plan_name)."
  }
}

variable "role_collection_assignments" {
  description = <<-EOT
    Mapa "role collection" => lista de usuários (e-mail no SAP ID service).
    Ex.: { "Subaccount Administrator" = ["voce@exemplo.com"] }
  EOT
  type        = map(list(string))
  default     = {}
}
