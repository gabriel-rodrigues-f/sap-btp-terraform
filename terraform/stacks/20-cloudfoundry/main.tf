#
# Stack 20 - camada de PLATAFORMA Cloud Foundry (provider cloudfoundry/cloudfoundry)
#
#   org (criada pelo stack 10) -> papéis de org -> spaces -> papéis de space
#                                                         -> instâncias -> service keys
#
# Nomes, labels e personas vêm do stack 10: a governança é definida UMA vez.
#

locals {
  access = local.account.access

  # -------------------------------------------------------------------------
  # RBAC: persona -> papéis no Cloud Foundry (mesmas personas do stack 10).
  # -------------------------------------------------------------------------
  org_roles = {
    organization_manager         = local.access.platform_admins
    organization_user            = local.access.developers
    organization_auditor         = local.access.auditors
    organization_billing_manager = local.access.finops
  }

  space_roles = {
    space_manager = local.access.platform_admins
    # O deployer precisa ser Space Developer: é esse papel que cria instâncias.
    space_developer = distinct(concat(local.access.platform_admins, local.access.developers, [local.access.deployer]))
    space_auditor   = local.access.auditors
  }

  # Achata spaces/instâncias para nomear tudo de uma vez no módulo naming.
  instances = merge([
    for space, cfg in var.spaces : {
      for key, si in cfg.service_instances : "${space}/${key}" => merge(si, { space = space, key = key })
    }
  ]...)
}

module "naming" {
  source = "../../modules/naming"

  business_unit = local.account.conventions.business_unit
  workload      = local.account.conventions.workload
  environment   = local.account.conventions.environment
  region        = local.account.conventions.region
  unique_suffix = local.account.conventions.unique_suffix

  service_instances = {
    for k, si in local.instances : k => { offering = si.offering, instance = si.instance }
  }
}

module "org_access" {
  source = "../../modules/cf-org-access"

  org_id = local.account.cf_org_id
  roles  = local.org_roles

  # Quem criou o ambiente CF já é Org Manager (o BTP faz isso), e a API do CF
  # recusa criar um papel repetido.
  exclude_users = [local.access.deployer]
}

module "space" {
  source   = "../../modules/cf-space"
  for_each = var.spaces

  org_id      = module.org_access.org_id # só depois dos papéis de org
  name        = each.key
  allow_ssh   = each.value.allow_ssh
  labels      = local.account.labels.cf
  annotations = local.account.labels.cf_annotation
  roles       = local.space_roles

  service_instances = {
    for k, si in local.instances : si.key => {
      name     = module.naming.service_instances[k]
      offering = si.offering
      plan     = si.plan
      tags     = si.tags
      keys     = si.keys
      parameters = (si.offering == "xsuaa" && si.parameters == null
        ? jsonencode({ xsappname = module.naming.service_instances[k], "tenant-mode" = "dedicated" })
      : si.parameters)
    }
    if si.space == each.key
  }
}
