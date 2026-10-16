variable "org_id" {
  description = "GUID da org Cloud Foundry."
  type        = string
}

variable "roles" {
  description = <<-EOT
    Usuários por papel na org. Papéis válidos: organization_manager,
    organization_user, organization_auditor, organization_billing_manager.
    Todo usuário listado vira também organization_user (membro da org),
    pré-requisito para receber papéis em spaces.
  EOT
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for role in keys(var.roles) :
      contains(["organization_manager", "organization_user", "organization_auditor", "organization_billing_manager"], role)
    ])
    error_message = "Papel de org inválido."
  }
}

variable "exclude_users" {
  description = <<-EOT
    Usuários que NÃO recebem papel de org por aqui. Use para quem cria o
    ambiente: o BTP já o torna Org Manager, e a API do Cloud Foundry recusa
    criar um papel que já existe.
  EOT
  type        = list(string)
  default     = []
}

variable "user_origin" {
  description = "Origem (IdP) dos usuários no UAA. sap.ids = SAP ID service."
  type        = string
  default     = "sap.ids"
}
