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
    "alert-notification"                  = "ans"
    "apimanagement-apiportal-trial"       = "apim"
    "apimanagement-devportal-trial"       = "devportal"
    "application-logs"                    = "log"
    "auditlog-management"                 = "audit"
    "autoscaler"                          = "asc"
    "build-workzone-standard"             = "wz"
    "business-entity-recognition-trial"   = "ber"
    "cis"                                 = "cis"
    "connectivity"                        = "conn"
    "credstore"                           = "cred"
    "data-attribute-recommendation-trial" = "dar"
    "destination"                         = "dest"
    "document-translation"                = "dtr"
    "feature-flags"                       = "ff"
    "hana"                                = "hdi"
    "hana-cloud"                          = "hana"
    "html5-apps-repo"                     = "html5"
    "identity"                            = "ias"
    "it-rt"                               = "cpi"
    "jobscheduler"                        = "job"
    "objectstore"                         = "obj"
    "postgresql-db"                       = "pg"
    "process-automation-service"          = "spa"
    "redis-cache"                         = "redis"
    "saas-registry"                       = "saas"
    "service-manager"                     = "sm"
    "theming"                             = "thm"
    "transport"                           = "tms"
    "xsuaa"                               = "uaa"
  }
  abbreviations = merge(local.default_abbreviations, var.abbreviations)

  # Serviço sem abreviação cadastrada usa o próprio nome: nunca quebra, mas
  # vale cadastrar para manter os nomes curtos.
  service_instances = {
    for key, si in var.service_instances :
    key => join("-", compact([lookup(local.abbreviations, si.offering, si.offering), si.scope, local.base, si.instance]))
  }
}
