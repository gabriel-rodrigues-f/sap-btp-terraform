variable "business_unit" {
  description = "Unidade de negócio dona do directory (ex.: corporate-it). O directory agrupa os workloads dela."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.business_unit)) && length(var.business_unit) <= 30
    error_message = "business_unit: kebab-case minúsculo, começando por letra, até 30 caracteres."
  }
}

variable "workload" {
  description = "Carga de trabalho / domínio de negócio, em kebab-case (ex.: application-integration)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.workload)) && length(var.workload) <= 30
    error_message = "workload: kebab-case minúsculo, começando por letra, até 30 caracteres (ex.: application-integration)."
  }
}

variable "environment" {
  description = "Ambiente. Valores fechados para que relatórios de custo agrupem sem variações (qa x QA x hml)."
  type        = string

  validation {
    condition     = contains(["sbx", "dev", "qa", "prd"], var.environment)
    error_message = "environment deve ser sbx, dev, qa ou prd."
  }
}

variable "region" {
  description = "Região do BTP (ex.: us10, eu10, br10). Entra no nome para deixar óbvio onde o recurso roda."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}[0-9]{2}$", var.region))
    error_message = "region deve seguir o padrão do BTP: duas letras + dois dígitos (us10, eu10, br10...)."
  }
}

variable "unique_suffix" {
  description = <<-EOT
    Sufixo curto para nomes que precisam ser ÚNICOS NA REGIÃO entre todos os
    clientes SAP (subdomínios e org Cloud Foundry). Use algo estável do seu
    global account, nunca aleatório (mudaria a cada recriação).
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{4,8}$", var.unique_suffix))
    error_message = "unique_suffix: 4 a 8 caracteres minúsculos/números."
  }
}

variable "service_instances" {
  description = <<-EOT
    Instâncias que precisam de nome (chave lógica => serviço e número de instância).
    O nome final segue <abreviação>-<workload>-<ambiente>-<região>-<nnn>.
  EOT
  type = map(object({
    offering = string
    instance = optional(string, "001")
  }))
  default = {}

  validation {
    condition     = alltrue([for si in values(var.service_instances) : can(regex("^[0-9]{3}$", si.instance))])
    error_message = "instance deve ter 3 dígitos (001, 002...), como no CAF."
  }
}

variable "abbreviations" {
  description = "Abreviações extras/sobrescritas por serviço (offering => abreviação)."
  type        = map(string)
  default     = {}
}
