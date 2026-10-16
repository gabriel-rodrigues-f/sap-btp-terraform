variable "value_streams" {
  description = <<-EOT
    Value streams da SAP que viram spaces (código => nome). Cada um recebe o
    kit de serviços de aplicação (value_stream_services) e a label value-stream,
    o que permite ver o custo por processo de negócio.
  EOT
  type        = map(string)
  default = {
    o2c = "order-to-cash"
    p2p = "procure-to-pay"
    r2r = "record-to-report"
    h2r = "hire-to-retire"
    d2o = "design-to-operate"
  }

  validation {
    condition     = alltrue([for code in keys(var.value_streams) : can(regex("^[a-z0-9]{2,6}$", code))])
    error_message = "Código do value stream: 2 a 6 caracteres minúsculos/números (ex.: o2c)."
  }
}

variable "value_stream_services" {
  description = "Kit de serviços criado em CADA space de value stream (o nome leva o código do value stream)."
  type = map(object({
    offering   = string
    plan       = string
    instance   = optional(string, "001")
    parameters = optional(string)
    tags       = optional(list(string))
    keys       = optional(list(string), [])
  }))
  default = {
    destination      = { offering = "destination", plan = "lite", keys = ["cicd"] }
    xsuaa            = { offering = "xsuaa", plan = "application", keys = ["cicd"] }
    html5-repo-host  = { offering = "html5-apps-repo", plan = "app-host", keys = ["cicd"] }
    application-logs = { offering = "application-logs", plan = "lite" }
  }
}

variable "shared_services" {
  description = "Uma instância de cada serviço compartilhado, no space shared-services."
  type = map(object({
    offering   = string
    plan       = string
    instance   = optional(string, "001")
    parameters = optional(string)
    tags       = optional(list(string))
    keys       = optional(list(string), [])
  }))
  default = {
    connectivity                  = { offering = "connectivity", plan = "lite" }
    html5-runtime                 = { offering = "html5-apps-repo", plan = "app-runtime", keys = ["cicd"] }
    feature-flags                 = { offering = "feature-flags", plan = "lite", keys = ["cicd"] }
    alert-notification            = { offering = "alert-notification", plan = "standard", keys = ["monitoring"] }
    autoscaler                    = { offering = "autoscaler", plan = "standard" }
    jobscheduler                  = { offering = "jobscheduler", plan = "free", keys = ["cicd"] }
    credstore                     = { offering = "credstore", plan = "trial", keys = ["cicd"] }
    theming                       = { offering = "theming", plan = "standard" }
    transport                     = { offering = "transport", plan = "standard", keys = ["cicd"] }
    identity                      = { offering = "identity", plan = "application", keys = ["cicd"] }
    process-automation            = { offering = "process-automation-service", plan = "standard", keys = ["cicd"] }
    document-translation          = { offering = "document-translation", plan = "trial", keys = ["cicd"] }
    business-entity-recognition   = { offering = "business-entity-recognition-trial", plan = "standard", keys = ["cicd"] }
    data-attribute-recommendation = { offering = "data-attribute-recommendation-trial", plan = "standard", keys = ["cicd"] }
    redis                         = { offering = "redis-cache", plan = "trial", keys = ["cicd"] }
    postgresql                    = { offering = "postgresql-db", plan = "trial", keys = ["cicd"] }
  }
}

variable "space_roles" {
  description = <<-EOT
    Papéis nos spaces. Vazio = derivado das personas do stack 10
    (platform_admins: manager + developer; developers: developer; auditors: auditor).
  EOT
  type        = map(list(string))
  default     = {}
}
