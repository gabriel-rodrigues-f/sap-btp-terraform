variable "subaccount_id" {
  description = "ID do subaccount onde o ambiente Cloud Foundry será habilitado."
  type        = string
}

variable "org_name" {
  description = "Nome da org Cloud Foundry. Precisa ser único na região inteira (não só no seu global account)."
  type        = string
}

variable "plan_name" {
  description = <<-EOT
    Plano do ambiente Cloud Foundry. Em conta trial costuma ser "trial"; em
    contas pagas, "standard". Confira com:
    btp list accounts/available-environment --subaccount <id>
  EOT
  type        = string
  default     = "standard"
}

variable "landscape_label" {
  description = "Landscape específico (ex.: cf-us10-001). null = o BTP escolhe. Necessário só em regiões com mais de um landscape."
  type        = string
  default     = null
}

variable "create_timeout" {
  description = "Tempo máximo para criar o ambiente (a org leva alguns minutos para ficar pronta)."
  type        = string
  default     = "30m"
}
