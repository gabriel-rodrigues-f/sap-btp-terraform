#
# Stack 10 - camada de CONTA (provider SAP/btp)
#
#   directory (unidade de negócio)
#     └── subaccount <workload>-<ambiente>-<região>
#           ├── entitlements, assinaturas, instâncias e service keys
#           └── ambiente Cloud Foundry (org)
#
# Tudo nasce com nome padronizado (módulo naming), labels de FinOps (módulo
# finops-labels) e permissões por persona (locals abaixo).
#

data "btp_whoami" "deployer" {}

locals {
  # "203d9eebtrial-ga" -> "203d9eeb": estável, curto e único por global account.
  unique_suffix = coalesce(var.unique_suffix, substr(replace(trimsuffix(var.globalaccount, "-ga"), "trial", ""), 0, 8))

  # -------------------------------------------------------------------------
  # RBAC: persona -> role collections. A MESMA persona é traduzida para os
  # papéis de org/space no stack 20, então quem é auditor é auditor em tudo.
  # -------------------------------------------------------------------------
  directory_roles = {
    "Directory Administrator" = var.access.platform_admins
    "Directory Viewer"        = distinct(concat(var.access.auditors, var.access.finops))
  }

  subaccount_roles = {
    "Subaccount Administrator"  = var.access.platform_admins
    "Subaccount Viewer"         = distinct(concat(var.access.developers, var.access.auditors, var.access.finops))
    "Destination Administrator" = var.access.developers
  }
}

module "naming" {
  source = "../../modules/naming"

  business_unit = var.business_unit
  workload      = var.workload
  environment   = var.environment
  region        = var.region
  unique_suffix = local.unique_suffix

  service_instances = {
    for key, si in var.service_instances : key => { offering = si.offering, instance = si.instance }
  }
}

module "labels" {
  source = "../../modules/finops-labels"

  business_unit       = var.business_unit
  workload            = var.workload
  environment         = var.environment
  region              = var.region
  cost_center         = var.finops.cost_center
  owner               = var.finops.owner
  owner_contact       = var.finops.owner_contact
  criticality         = var.finops.criticality
  data_classification = var.finops.data_classification
  extra               = var.finops.extra
}

module "directory" {
  source = "../../modules/btp-directory"

  name        = module.naming.directory
  subdomain   = module.naming.directory_subdomain
  description = "Unidade de negócio ${var.business_unit} (gerenciado por Terraform)"
  labels      = module.labels.btp_directory

  # O directory precisa receber a cota ANTES de repassá-la ao subaccount.
  entitlements                = var.entitlements
  role_collection_assignments = local.directory_roles
}

module "subaccount" {
  source = "../../modules/btp-subaccount"

  name        = module.naming.subaccount
  subdomain   = module.naming.subaccount_subdomain
  region      = var.region
  description = "${var.workload} | ${var.environment} | ${var.region} (gerenciado por Terraform)"
  parent_id   = module.directory.id # só existe depois da cota e das permissões do directory
  usage       = var.environment == "prd" ? "USED_FOR_PRODUCTION" : "NOT_USED_FOR_PRODUCTION"
  labels      = module.labels.btp

  entitlements                = var.entitlements
  role_collection_assignments = local.subaccount_roles
}

module "services" {
  source = "../../modules/btp-services"

  subaccount_id = module.subaccount.id # só existe depois dos entitlements
  labels        = module.labels.btp
  subscriptions = var.subscriptions

  service_instances = {
    for key, si in var.service_instances : key => merge(si, { name = module.naming.service_instances[key] })
  }
}

module "cloudfoundry" {
  source = "../../modules/btp-cloudfoundry"

  subaccount_id = module.subaccount.id
  org_name      = module.naming.cf_org
  plan_name     = var.cf_environment_plan
}
