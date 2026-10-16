#
# Stack 20 - camada de PLATAFORMA Cloud Foundry (provider cloudfoundry/cloudfoundry)
#
#   org (criada pelo stack 10) -> papéis de org
#     -> spaces por VALUE STREAM (o2c, p2p, r2r, h2r, d2o) + shared-services
#          -> papéis de space -> instâncias -> service keys
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

  space_roles = length(var.space_roles) > 0 ? var.space_roles : {
    space_manager = local.access.platform_admins
    # O deployer precisa ser Space Developer: é esse papel que cria instâncias.
    space_developer = distinct(concat(local.access.platform_admins, local.access.developers, [local.access.deployer]))
    space_auditor   = local.access.auditors
  }

  # Spaces = value streams (com o kit) + shared-services.
  spaces = merge(
    {
      for code, name in var.value_streams : code => {
        value_stream = name
        scope        = code
        services     = var.value_stream_services
      }
    },
    {
      "shared-services" = {
        value_stream = "shared"
        scope        = null
        services     = var.shared_services
      }
    },
  )

  # Achata spaces/instâncias para nomear tudo de uma vez no módulo naming.
  instances = merge([
    for space, cfg in local.spaces : {
      for key, si in cfg.services : "${space}/${key}" => merge(si, { space = space, key = key, scope = cfg.scope })
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
    for k, si in local.instances : k => { offering = si.offering, scope = si.scope, instance = si.instance }
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
  for_each = local.spaces

  org_id = module.org_access.org_id # só depois dos papéis de org
  name   = each.key
  roles  = local.space_roles

  # FinOps por processo de negócio: value-stream em labels, nome completo em annotation.
  labels      = merge(local.account.labels.cf, { "value-stream" = each.value.scope == null ? "shared" : each.value.scope })
  annotations = merge(local.account.labels.cf_annotation, { "value-stream-name" = each.value.value_stream })

  service_instances = {
    for k, si in local.instances : si.key => {
      name     = module.naming.service_instances[k]
      offering = si.offering
      plan     = si.plan
      tags     = si.tags
      keys     = si.keys
      parameters = (si.offering == "xsuaa" && si.plan == "application" && si.parameters == null
        ? jsonencode({ xsappname = module.naming.service_instances[k], "tenant-mode" = "dedicated" })
      : si.parameters)
    }
    if si.space == each.key
  }
}
