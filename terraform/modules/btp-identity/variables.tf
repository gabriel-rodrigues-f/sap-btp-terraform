variable "subaccount_id" {
  description = "ID do subaccount que vai confiar no SAP Cloud Identity Services (IAS)."
  type        = string
}

variable "onboarding_plan" {
  description = "Plano da assinatura de onboarding do IAS (sap-identity-services-onboarding)."
  type        = string
  default     = "default"
}

variable "trust_name" {
  description = "Nome de exibição do trust (aparece na tela de login quando há mais de um IdP)."
  type        = string
  default     = "SAP Cloud Identity Services"
}

variable "origin" {
  description = "Origin key do trust. null = o BTP gera (ex.: sap.custom). É o 'origin' usado nas role collections."
  type        = string
  default     = null
}

variable "auto_create_shadow_users" {
  description = <<-EOT
    true = qualquer usuário do IAS entra e ganha um shadow user no subaccount.
    false (padrão) = só entra quem recebeu role collection explicitamente (menor privilégio).
  EOT
  type        = bool
  default     = false
}
