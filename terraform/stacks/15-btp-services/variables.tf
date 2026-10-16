variable "app_users" {
  description = <<-EOT
    Usuários do IAS (e-mail) que recebem as role collections de TODAS as
    aplicações. null = o próprio usuário que executa o Terraform.
  EOT
  type        = list(string)
  default     = null
}

variable "disable_default_idp_logon" {
  description = "Desliga o SAP ID service (sap.default) como opção de login das aplicações; só o IAS fica disponível."
  type        = bool
  default     = true
}

variable "subscriptions" {
  description = <<-EOT
    Aplicações SaaS e as role collections de admin de cada uma (atribuídas ao
    usuário do IAS assim que a assinatura existe). Nome técnico da app:
    `btp list accounts/subscription --subaccount <id>`.
  EOT
  type = map(object({
    app_name         = string
    plan             = string
    parameters       = optional(string)
    role_collections = optional(list(string), [])
  }))
  default = {
    integration-suite = {
      app_name         = "it-cpitrial06-prov"
      plan             = "trial"
      role_collections = ["Integration_Provisioner"]
    }
    business-application-studio = {
      app_name         = "sapappstudiotrial"
      plan             = "trial"
      role_collections = ["Business_Application_Studio_Administrator", "Business_Application_Studio_Developer", "Business_Application_Studio_Extension_Deployer"]
    }
    work-zone = {
      app_name         = "SAPLaunchpadSMS"
      plan             = "standard"
      role_collections = ["Launchpad_Admin"]
    }
    build-code = {
      app_name         = "build-code"
      plan             = "free"
      role_collections = ["Build Code Administrator", "Build Code Developer"]
    }
    build-apps         = { app_name = "sap-appgyver-ee", plan = "free" }
    process-automation = { app_name = "process-automation", plan = "free" }
    hana-cloud-tools = {
      app_name         = "hana-cloud-tools"
      plan             = "tools"
      role_collections = ["SAP HANA Cloud Administrator"]
    }
    cicd                       = { app_name = "cicd-app", plan = "trial" }
    cloud-transport-management = { app_name = "alm-ts", plan = "lite" }
    automation-pilot = {
      app_name         = "automationpilot"
      plan             = "free"
      role_collections = ["AutomationPilot_Admin", "AutomationPilot_Developer"]
    }
    auditlog-viewer         = { app_name = "auditlog-viewer", plan = "free" }
    feature-flags-dashboard = { app_name = "feature-flags-dashboard", plan = "dashboard" }
  }
}

variable "service_instances" {
  description = <<-EOT
    Instâncias de PLATAFORMA no nível do subaccount (Service Manager), para
    consumo fora do Cloud Foundry. 'scope' entra no nome; 'keys' = consumidores.
  EOT
  type = map(object({
    offering   = string
    plan       = string
    scope      = optional(string)
    instance   = optional(string, "001")
    parameters = optional(string)
    keys       = optional(list(string), [])
  }))
  default = {
    auditlog    = { offering = "auditlog-management", plan = "default", keys = ["siem"] }
    sm-audit    = { offering = "service-manager", plan = "subaccount-audit", scope = "audit", keys = ["finops-reporting"] }
    sm-admin    = { offering = "service-manager", plan = "subaccount-admin", scope = "admin", keys = ["platform-automation"] }
    cis-local   = { offering = "cis", plan = "local", scope = "local", keys = ["platform-automation"] }
    cis-central = { offering = "cis", plan = "central", scope = "central", keys = ["platform-automation"] }
    xsuaa-api   = { offering = "xsuaa", plan = "apiaccess", scope = "api", keys = ["platform-automation"] }
  }
}
