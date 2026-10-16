# Todos os valores que viram LABEL no Cloud Foundry precisam respeitar a regra
# de metadados do CF: até 63 caracteres, letras/números/-/_/., começando e
# terminando com letra ou número. Validamos aqui para o erro aparecer no plan,
# e não no meio do apply. (E-mail e URL não cabem nessa regra: vão em annotation.)

variable "cost_center" {
  description = "Centro de custo que paga a conta (chave nº 1 do chargeback)."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", var.cost_center))
    error_message = "cost_center: até 63 caracteres, letras, números, -, _ ou ."
  }
}

variable "business_unit" {
  description = "Unidade de negócio (showback por área)."
  type        = string
}

variable "workload" {
  description = "Aplicação/carga de trabalho (custo por produto)."
  type        = string
}

variable "environment" {
  description = "Ambiente (separa custo produtivo do não produtivo)."
  type        = string
}

variable "region" {
  description = "Região do BTP."
  type        = string
}

variable "owner" {
  description = "Time dono (identificador sem espaços; o e-mail vai em owner_contact)."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", var.owner))
    error_message = "owner: identificador do time (ex.: platform-team), sem espaços nem @."
  }
}

variable "owner_contact" {
  description = "E-mail de contato do dono (label no BTP, annotation no Cloud Foundry)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner_contact))
    error_message = "owner_contact deve ser um e-mail."
  }
}

variable "criticality" {
  description = "Criticidade para o negócio (prioriza otimização e define SLA de suporte)."
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["low", "medium", "high", "mission-critical"], var.criticality)
    error_message = "criticality: low, medium, high ou mission-critical."
  }
}

variable "data_classification" {
  description = "Classificação dos dados tratados (governança e compliance)."
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification: public, internal, confidential ou restricted."
  }
}

variable "iac_repository" {
  description = "Nome curto do repositório de IaC (rastreia quem criou o recurso)."
  type        = string
  default     = "sap-btp-terraform"
}

variable "iac_repository_url" {
  description = "URL do repositório de IaC (annotation, porque URL não cabe em label do CF)."
  type        = string
  default     = "https://github.com/gabriel-rodrigues-f/sap-btp-terraform"
}

variable "extra" {
  description = "Labels adicionais da empresa (ex.: { project = \"s4-migration\" })."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.extra) : can(regex("^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$", v))])
    error_message = "Valores em extra precisam seguir a regra de label do Cloud Foundry."
  }
}
