mock_provider "btp" {}

variables {
  subaccount_id = "00000000-0000-0000-0000-000000000000"
}

run "trust_aponta_para_o_tenant_da_assinatura" {
  command = apply

  override_resource {
    target = btp_subaccount_subscription.onboarding
    values = {
      subscription_url = "https://abc123.trial-accounts.ondemand.com/admin"
    }
  }

  override_resource {
    target = btp_subaccount_trust_configuration.ias
    values = {
      origin = "sap.custom"
    }
  }

  assert {
    condition     = btp_subaccount_trust_configuration.ias.identity_provider == "abc123.trial-accounts.ondemand.com"
    error_message = "O trust deve usar o host extraído da URL da assinatura."
  }

  assert {
    condition     = btp_subaccount_trust_configuration.ias.auto_create_shadow_users == false
    error_message = "Por padrão, só entra no subaccount quem recebeu role collection."
  }

  assert {
    condition     = btp_subaccount_security_settings.this.default_identity_provider == "sap.custom"
    error_message = "O IAS deve ser o IdP padrão das aplicações."
  }

  assert {
    condition     = output.ias_admin_console == "https://abc123.trial-accounts.ondemand.com/admin"
    error_message = "Output do console do IAS."
  }
}
