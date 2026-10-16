variable "spaces" {
  description = <<-EOT
    Spaces da org (chave = nome do space, pela FINALIDADE: o ambiente já está
    no nome da org). Cada instância recebe nome da convenção e, em 'keys',
    os consumidores que ganham uma service key (sk-<consumidor>).
    Para xsuaa sem 'parameters', o xsappname é preenchido com o nome da instância.
  EOT
  type = map(object({
    allow_ssh = optional(bool, false)
    service_instances = optional(map(object({
      offering   = string
      plan       = string
      instance   = optional(string, "001")
      parameters = optional(string)
      tags       = optional(list(string))
      keys       = optional(list(string), [])
    })), {})
  }))

  default = {
    integration = {
      service_instances = {
        destination        = { offering = "destination", plan = "lite", keys = ["cicd", "integration-suite"] }
        xsuaa              = { offering = "xsuaa", plan = "application", keys = ["cicd"] }
        connectivity       = { offering = "connectivity", plan = "lite" }
        feature-flags      = { offering = "feature-flags", plan = "lite", keys = ["cicd"] }
        alert-notification = { offering = "alert-notification", plan = "standard", keys = ["monitoring"] }
        html5-repo-host    = { offering = "html5-apps-repo", plan = "app-host", keys = ["cicd"] }
        application-logs   = { offering = "application-logs", plan = "lite" }
      }
    }
  }
}
