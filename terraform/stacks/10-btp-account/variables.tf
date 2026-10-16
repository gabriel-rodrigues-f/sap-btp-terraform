# ---------------------------------------------------------------------------
# Onde: global account e região
# ---------------------------------------------------------------------------

variable "globalaccount" {
  description = "SUBDOMÍNIO do global account (não é o nome nem o ID). Na trial termina com '-ga'. Veja: btp --info"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.globalaccount))
    error_message = "Informe o subdomínio do global account (ex.: 1a2b3c4dtrial-ga), não o nome de exibição."
  }
}

variable "region" {
  description = "Região do subaccount. A trial oferece us10 (AWS, Virgínia) e ap21 (Azure, Singapura)."
  type        = string
  default     = "us10"
}

variable "unique_suffix" {
  description = "Sufixo para nomes únicos na região. null = derivado do subdomínio do global account (ex.: 203d9eeb)."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# O quê: convenção de nomes (estilo Azure CAF)
# ---------------------------------------------------------------------------

variable "business_unit" {
  description = "Unidade de negócio. Vira o nome do directory que agrupa os subaccounts dela."
  type        = string
  default     = "corporate-it"
}

variable "workload" {
  description = "Workload/aplicação. Primeiro segmento do nome do subaccount."
  type        = string
  default     = "application-integration"
}

variable "environment" {
  description = "Ambiente: sbx, dev, qa ou prd."
  type        = string
  default     = "qa"
}

# ---------------------------------------------------------------------------
# Quem paga: labels de FinOps
# ---------------------------------------------------------------------------

variable "finops" {
  description = "Dados de alocação de custo aplicados como labels em todos os recursos."
  type = object({
    cost_center         = string
    owner               = string
    owner_contact       = string
    criticality         = optional(string, "medium")
    data_classification = optional(string, "internal")
    extra               = optional(map(string), {})
  })
}

# ---------------------------------------------------------------------------
# Quem acessa: personas (RBAC). A tradução persona -> papéis está em main.tf.
# ---------------------------------------------------------------------------

variable "access" {
  description = <<-EOT
    Usuários (e-mail do SAP ID service) por persona. Cada persona recebe um
    conjunto coerente de papéis no directory, no subaccount, na org e no space.
  EOT
  type = object({
    platform_admins = list(string)
    developers      = optional(list(string), [])
    auditors        = optional(list(string), [])
    finops          = optional(list(string), [])
  })

  validation {
    condition     = length(var.access.platform_admins) > 0
    error_message = "Defina ao menos um platform_admin."
  }

  validation {
    condition = alltrue([
      for u in flatten([var.access.platform_admins, var.access.developers, var.access.auditors, var.access.finops]) :
      can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", u))
    ])
    error_message = "Todos os usuários devem ser e-mails."
  }
}

# ---------------------------------------------------------------------------
# Serviços
# ---------------------------------------------------------------------------

variable "cf_environment_plan" {
  description = "Plano do ambiente Cloud Foundry: 'trial' em conta trial, 'standard' em conta paga."
  type        = string
  default     = "trial"
}

variable "entitlements" {
  description = <<-EOT
    Planos liberados para o directory E para o subaccount (global account ->
    directory -> subaccount). Os padrões são planos ELASTIC/APPLICATION da trial,
    que não consomem cota numérica.
  EOT
  type = list(object({
    service_name = string
    plan_name    = string
    amount       = optional(number)
  }))
  default = [
    { service_name = "cloudfoundry", plan_name = "trial" }, # ambiente CF (org)
    { service_name = "destination", plan_name = "lite" },
    { service_name = "xsuaa", plan_name = "application" },
    { service_name = "connectivity", plan_name = "lite" },
    { service_name = "feature-flags", plan_name = "lite" },
    { service_name = "alert-notification", plan_name = "standard" },
    { service_name = "html5-apps-repo", plan_name = "app-host" },
    { service_name = "application-logs", plan_name = "lite" },
    { service_name = "auditlog-management", plan_name = "default" },
    { service_name = "service-manager", plan_name = "subaccount-audit" },
    { service_name = "feature-flags-dashboard", plan_name = "dashboard" }, # assinaturas SaaS
    { service_name = "auditlog-viewer", plan_name = "free" },
    { service_name = "automationpilot", plan_name = "free" },
  ]
}

variable "subscriptions" {
  description = "Assinaturas SaaS (nome TÉCNICO da app, veja `btp list accounts/subscription`)."
  type = list(object({
    app_name   = string
    plan_name  = string
    parameters = optional(string)
  }))
  default = [
    { app_name = "feature-flags-dashboard", plan_name = "dashboard" },
    { app_name = "auditlog-viewer", plan_name = "free" },
    { app_name = "automationpilot", plan_name = "free" },
  ]
}

variable "service_instances" {
  description = <<-EOT
    Instâncias no nível do SUBACCOUNT (Service Manager), para consumo fora do
    Cloud Foundry (SIEM, ferramentas de FinOps, pipelines). 'keys' = consumidores.
  EOT
  type = map(object({
    offering   = string
    plan       = string
    instance   = optional(string, "001")
    parameters = optional(string)
    keys       = optional(list(string), [])
  }))
  default = {
    auditlog = { offering = "auditlog-management", plan = "default", keys = ["siem"] }
    sm-audit = { offering = "service-manager", plan = "subaccount-audit", keys = ["finops-reporting"] }
  }
}
