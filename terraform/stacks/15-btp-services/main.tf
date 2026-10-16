#
# Stack 15 - IDENTIDADE e SERVIÇOS do subaccount (provider SAP/btp)
#
#   IAS (onboarding + trust + IdP padrão)  ->  sap.default fora do login
#     -> assinaturas SaaS + role collections no usuário do IAS
#     -> instâncias de plataforma (Service Manager) + service keys
#
# Separado do stack 10 porque desligar o sap.default exige um bloco `import`
# com o ID do subaccount, que precisa ser conhecido no plan (vem do stack 10).
#

locals {
  app_users = coalesce(var.app_users, [local.account.access.deployer])
}

module "naming" {
  source = "../../modules/naming"

  business_unit = local.account.conventions.business_unit
  workload      = local.account.conventions.workload
  environment   = local.account.conventions.environment
  region        = local.account.conventions.region
  unique_suffix = local.account.conventions.unique_suffix

  service_instances = {
    for key, si in var.service_instances : key => { offering = si.offering, scope = si.scope, instance = si.instance }
  }
}

module "identity" {
  source = "../../modules/btp-identity"

  subaccount_id = local.account.subaccount_id
}

# O trust padrão (SAP ID service) já existe em todo subaccount: o Terraform o
# IMPORTA para gerenciá-lo, em vez de criar. O provider trata sap.default de
# forma especial (sem identity_provider e sem delete no destroy).
import {
  to = btp_subaccount_trust_configuration.sap_default
  id = "${local.account.subaccount_id},sap.default"
}

resource "btp_subaccount_trust_configuration" "sap_default" {
  subaccount_id            = local.account.subaccount_id
  identity_provider        = ""
  name                     = "sap.default"
  available_for_user_logon = !var.disable_default_idp_logon
  auto_create_shadow_users = false

  # Só tira o SAP ID do login depois que o IAS virou o IdP padrão:
  # nunca existe um momento sem forma de entrar nas aplicações.
  depends_on = [module.identity]
}

module "apps" {
  source = "../../modules/btp-apps"

  subaccount_id = module.identity.subaccount_id # espera o trust: algumas apps exigem o IAS
  subscriptions = var.subscriptions
  users         = local.app_users
  origin        = module.identity.origin
}

module "platform_services" {
  source = "../../modules/btp-services"

  subaccount_id = local.account.subaccount_id

  service_instances = {
    for key, si in var.service_instances : key => merge(si, { name = module.naming.service_instances[key] })
  }
}
