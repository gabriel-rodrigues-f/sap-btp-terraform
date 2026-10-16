variable "globalaccount" {
  description = "SUBDOMÍNIO do global account (não é o nome nem o ID). Na trial termina com '-ga'. Veja: btp --info"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.globalaccount))
    error_message = "Informe o subdomínio do global account (ex.: 1a2b3c4dtrial-ga), não o nome de exibição."
  }
}

variable "region" {
  description = "Região do subaccount. A trial só oferece us10 (AWS, Virgínia) e ap21 (Azure, Singapura)."
  type        = string
  default     = "us10"
}

variable "project" {
  description = "Nome curto do projeto. Compõe subdomínio, org e nomes de recursos."
  type        = string
  default     = "btp-poc"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project: 2-21 caracteres, minúsculas, números e hífen, começando por letra."
  }
}

variable "stage" {
  description = "Estágio/ambiente (dev, qas, prd...). Cada estágio é um subaccount separado."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.stage))
    error_message = "stage: 2-8 caracteres alfanuméricos minúsculos."
  }
}

variable "directory_name" {
  description = "Se informado, cria um directory e coloca o subaccount dentro dele. null = direto no global account."
  type        = string
  default     = null
}

variable "admins" {
  description = "E-mails (SAP ID service) que administram o subaccount e o space."
  type        = list(string)

  validation {
    condition     = length(var.admins) > 0 && alltrue([for a in var.admins : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", a))])
    error_message = "Informe ao menos um e-mail válido em admins."
  }
}

variable "admin_role_collections" {
  description = "Role collections atribuídas a cada admin no subaccount."
  type        = list(string)
  default     = ["Subaccount Administrator"]
}

variable "cf_environment_plan" {
  description = "Plano do ambiente Cloud Foundry: 'trial' em conta trial, 'standard' em conta paga."
  type        = string
  default     = "trial"
}

variable "entitlements" {
  description = "Entitlements do subaccount. Na trial, a memória do Cloud Foundry precisa estar LIVRE no global account (veja docs/01-pre-requisitos-trial.md)."
  type = list(object({
    service_name = string
    plan_name    = string
    amount       = optional(number)
  }))
  default = [
    { service_name = "APPLICATION_RUNTIME", plan_name = "MEMORY", amount = 1 }, # 1 GB de runtime CF
    { service_name = "destination", plan_name = "lite" },
  ]
}

variable "subscriptions" {
  description = "Assinaturas SaaS (ex.: BAS). Cada uma exige o entitlement correspondente em `entitlements`."
  type = list(object({
    app_name   = string
    plan_name  = string
    parameters = optional(string)
  }))
  default = []
}

variable "destinations" {
  description = "Destinations HTTP no nível do subaccount (chave = nome da destination)."
  type = map(object({
    url            = string
    description    = optional(string)
    proxy_type     = optional(string, "Internet")
    authentication = optional(string, "NoAuthentication")
    properties     = optional(map(string), {})
  }))
  default = {
    northwind = {
      url         = "https://services.odata.org/V4/Northwind/Northwind.svc"
      description = "OData publico de exemplo (criado via Terraform)"
    }
  }
}

variable "labels" {
  description = "Labels extras para directory e subaccount (somadas às labels padrão)."
  type        = map(set(string))
  default     = {}
}
