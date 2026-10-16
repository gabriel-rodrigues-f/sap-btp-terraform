variable "name" {
  description = "Nome de exibição do subaccount no cockpit."
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
  description = "Labels do subaccount (map de set de strings, formato exigido pela API do BTP)."
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

variable "subscriptions" {
  description = <<-EOT
    Assinaturas de aplicações SaaS (ex.: SAP Business Application Studio).
    Exigem o entitlement correspondente. 'parameters' é uma string JSON
    (jsonencode()/file() em HCL; heredoc em .tfvars).
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

variable "role_collection_assignments" {
  description = <<-EOT
    Mapa "role collection" => lista de usuários (e-mail no SAP ID service).
    Ex.: { "Subaccount Administrator" = ["voce@exemplo.com"] }
  EOT
  type        = map(list(string))
  default     = {}
}

variable "destinations" {
  description = <<-EOT
    Destinations HTTP no nível do subaccount. A chave do mapa é o nome da destination.
    Use apenas destinations SEM segredo aqui; credenciais devem vir de um cofre
    (ex.: variável sensível alimentada pelo pipeline), nunca do código.
  EOT
  type = map(object({
    url            = string
    description    = optional(string)
    proxy_type     = optional(string, "Internet")
    authentication = optional(string, "NoAuthentication")
    properties     = optional(map(string), {})
  }))
  default = {}
}
