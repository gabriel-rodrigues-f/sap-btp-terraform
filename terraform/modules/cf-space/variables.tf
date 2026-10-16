variable "org_id" {
  description = "GUID da org Cloud Foundry onde o space será criado."
  type        = string
}

variable "name" {
  description = "Nome do space."
  type        = string
}

variable "allow_ssh" {
  description = "Permite `cf ssh` nos containers. Desligado por padrão (menor superfície de ataque)."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels de metadados do Cloud Foundry (map simples de string)."
  type        = map(string)
  default     = {}
}

variable "roles" {
  description = <<-EOT
    Usuários por papel no space. Papéis válidos: space_manager, space_developer,
    space_auditor, space_supporter. Ex.: { space_developer = ["voce@exemplo.com"] }
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
  description = "Origem (IdP) dos usuários no UAA do Cloud Foundry. sap.ids = SAP ID service (padrão da trial)."
  type        = string
  default     = "sap.ids"
}

variable "service_instances" {
  description = <<-EOT
    Instâncias de serviço gerenciadas no space. A chave do mapa é o nome da instância.
    'parameters' é uma string JSON enviada ao service broker
    (jsonencode()/file("xs-security.json") em HCL; heredoc em .tfvars).
  EOT
  type = map(object({
    offering   = string
    plan       = string
    parameters = optional(string)
    tags       = optional(list(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for si in values(var.service_instances) : si.parameters == null || can(jsondecode(si.parameters))])
    error_message = "service_instances[*].parameters deve ser um JSON válido."
  }
}
