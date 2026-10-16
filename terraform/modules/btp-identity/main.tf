#
# Identidade das APLICAÇÕES do subaccount:
#   1. assina o onboarding do SAP Cloud Identity Services (cria/vincula o tenant
#      do IAS e dispara o e-mail de ativação para quem assinou)
#   2. cria o trust OIDC do subaccount com esse tenant
#   3. torna o IAS o IdP PADRÃO: quem abre uma aplicação vai direto para o login do IAS
#
# Desligar o SAP ID service (sap.default) é feito no stack, porque exige um
# bloco `import` (que só pode existir no root module).
#

resource "btp_subaccount_subscription" "onboarding" {
  subaccount_id = var.subaccount_id
  app_name      = "sap-identity-services-onboarding"
  plan_name     = var.onboarding_plan

  timeouts = {
    create = "30m"
    delete = "30m"
  }
}

locals {
  # subscription_url = https://<tenant>.trial-accounts.ondemand.com/admin -> <tenant>.trial-accounts.ondemand.com
  ias_host = element(split("/", btp_subaccount_subscription.onboarding.subscription_url), 2)
}

resource "btp_subaccount_trust_configuration" "ias" {
  subaccount_id            = var.subaccount_id
  identity_provider        = local.ias_host
  name                     = var.trust_name
  description              = "Trust OIDC com o tenant ${local.ias_host} (gerenciado por Terraform)"
  origin                   = var.origin
  available_for_user_logon = true
  auto_create_shadow_users = var.auto_create_shadow_users
}

resource "btp_subaccount_security_settings" "this" {
  subaccount_id = var.subaccount_id

  # Usuários de aplicações caem direto no IAS, sem tela de escolha de IdP.
  default_identity_provider = btp_subaccount_trust_configuration.ias.origin
}
