variable "space_name" {
  description = "Nome do space Cloud Foundry."
  type        = string
  default     = "dev"
}

variable "space_roles" {
  description = <<-EOT
    Papéis no space. Vazio = os admins do stack 10 viram space_manager e
    space_developer (o mínimo para o Ansible conseguir fazer cf push).
  EOT
  type        = map(list(string))
  default     = {}
}

variable "service_instances" {
  description = "Instâncias de serviço no space (chave = nome da instância). O Ansible faz bind de todas na aplicação."
  type = map(object({
    offering   = string
    plan       = string
    parameters = optional(string)
    tags       = optional(list(string))
  }))
  default = {
    "btp-poc-destination" = { offering = "destination", plan = "lite" }
  }
}
