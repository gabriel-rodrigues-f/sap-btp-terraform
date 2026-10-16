#
# Convenção de nomes inspirada no Azure Cloud Adoption Framework (CAF):
#
#   <workload>-<ambiente>-<região>[-<instância>]   ex.: application-integration-qa-us10
#
# - Directory = unidade de negócio (management group do CAF) -> corporate-it
# - Subaccount é o "resource group" do ambiente   -> application-integration-qa-us10
# - Recursos filhos ganham prefixo de TIPO        -> dest-application-integration-qa-us10-001
# - Nomes únicos globalmente ganham sufixo estável -> ...-qa-us10-203d9eeb
#
# Centralizar isso num módulo garante que TODOS os stacks gerem nomes iguais.
#

locals {
  base = "${var.workload}-${var.environment}-${var.region}"

  # Abreviações por tipo de serviço (equivalente aos prefixos do CAF: rg-, st-, kv-...).
  default_abbreviations = {
    "alert-notification"  = "ans"
    "application-logs"    = "log"
    "auditlog-management" = "audit"
    "autoscaler"          = "asc"
    "connectivity"        = "conn"
    "credstore"           = "cred"
    "destination"         = "dest"
    "feature-flags"       = "ff"
    "hana"                = "hdi"
    "hana-cloud"          = "hana"
    "html5-apps-repo"     = "html5"
    "jobscheduler"        = "job"
    "objectstore"         = "obj"
    "saas-registry"       = "saas"
    "service-manager"     = "sm"
    "transport"           = "tms"
    "xsuaa"               = "uaa"
  }
  abbreviations = merge(local.default_abbreviations, var.abbreviations)

  # Serviço sem abreviação cadastrada usa o próprio nome: nunca quebra, mas
  # vale cadastrar para manter os nomes curtos.
  service_instances = {
    for key, si in var.service_instances :
    key => "${lookup(local.abbreviations, si.offering, si.offering)}-${local.base}-${si.instance}"
  }
}
