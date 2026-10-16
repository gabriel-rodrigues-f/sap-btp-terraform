variable "subaccount_id" {
  description = "ID do subaccount."
  type        = string
}

variable "subscriptions" {
  description = <<-EOT
    Aplicações SaaS (chave lógica => assinatura). Use o NOME TÉCNICO da app
    (`btp list accounts/subscription`), que pode diferir do entitlement.
    'role_collections' são atribuídas ao usuário do IAS assim que a assinatura
    existe (as role collections só nascem com a assinatura).
    'custom_role_collections' cria role collections para apps que só entregam
    ROLES (ex.: Build Apps): nome => templates de role + prefixos do app id.
    Elas também são atribuídas aos usuários.
  EOT
  type = map(object({
    app_name         = string
    plan             = string
    parameters       = optional(string)
    role_collections = optional(list(string), [])
    custom_role_collections = optional(map(object({
      role_templates = list(string)
      app_prefixes   = list(string)
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.subscriptions) : s.parameters == null || can(jsondecode(s.parameters))])
    error_message = "subscriptions[*].parameters deve ser um JSON válido."
  }
}

variable "users" {
  description = "Usuários (e-mail no IAS) que recebem as role collections das aplicações."
  type        = list(string)
}

variable "origin" {
  description = "Origin key do trust com o IAS (output do módulo btp-identity)."
  type        = string
}
