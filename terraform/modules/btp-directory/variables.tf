variable "name" {
  description = "Nome do directory (unidade de negócio)."
  type        = string
}

variable "subdomain" {
  description = "Subdomínio do directory. Obrigatório com o feature AUTHORIZATIONS; único na região."
  type        = string
}

variable "description" {
  description = "Descrição do directory."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels de FinOps do directory (map de set)."
  type        = map(set(string))
  default     = {}
}

variable "entitlements" {
  description = <<-EOT
    Planos liberados para o directory. Com o feature ENTITLEMENTS, o subaccount
    só recebe o que o directory recebeu antes (global account -> directory -> subaccount).
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
  description = "Mapa role collection do directory => usuários (Directory Administrator, Directory Viewer)."
  type        = map(list(string))
  default     = {}

  validation {
    condition     = alltrue([for rc in keys(var.role_collection_assignments) : contains(["Directory Administrator", "Directory Viewer"], rc)])
    error_message = "No directory existem apenas Directory Administrator e Directory Viewer."
  }
}
