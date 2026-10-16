# Testes unitários com provider MOCKADO: rodam offline, sem credenciais BTP.
# Validam a LÓGICA do módulo (chaves de for_each, validações, achatamento),
# não o comportamento da API. Execute com: terraform -chdir=<módulo> test

mock_provider "btp" {}

variables {
  name      = "BTP POC (dev)"
  subdomain = "acme-btp-poc-dev"
  region    = "us10"

  entitlements = [
    { service_name = "APPLICATION_RUNTIME", plan_name = "MEMORY", amount = 1 },
    { service_name = "destination", plan_name = "lite" },
  ]

  role_collection_assignments = {
    "Subaccount Administrator"  = ["ana@example.com", "bia@example.com"]
    "Destination Administrator" = ["ana@example.com"]
  }

  destinations = {
    northwind = { url = "https://services.odata.org" }
  }
}

run "entitlements_usam_chave_estavel" {
  command = plan

  assert {
    condition = toset(keys(btp_subaccount_entitlement.this)) == toset([
      "APPLICATION_RUNTIME/MEMORY",
      "destination/lite",
    ])
    error_message = "As chaves do for_each devem ser service_name/plan_name."
  }

  assert {
    condition     = btp_subaccount_entitlement.this["APPLICATION_RUNTIME/MEMORY"].amount == 1
    error_message = "amount deve ser repassado para planos com cota numérica."
  }
}

run "role_collections_sao_achatadas_por_usuario" {
  command = plan

  assert {
    condition     = length(btp_subaccount_role_collection_assignment.this) == 3
    error_message = "Esperado 1 assignment por par role collection + usuário."
  }

  assert {
    condition     = contains(keys(btp_subaccount_role_collection_assignment.this), "Subaccount Administrator|bia@example.com")
    error_message = "Chave do assignment deve ser 'role collection|usuário'."
  }
}

run "destination_vira_json_com_padroes" {
  command = plan

  assert {
    condition = jsondecode(btp_subaccount_destination_generic.this["northwind"].destination_configuration) == {
      Name           = "northwind"
      Type           = "HTTP"
      URL            = "https://services.odata.org"
      ProxyType      = "Internet"
      Authentication = "NoAuthentication"
    }
    error_message = "A destination deve ser serializada com Name/Type/URL/ProxyType/Authentication."
  }
}

run "rejeita_subdominio_invalido" {
  command = plan

  variables {
    subdomain = "Sub_Dominio_Invalido"
  }

  expect_failures = [var.subdomain]
}

run "rejeita_entitlement_duplicado" {
  command = plan

  variables {
    entitlements = [
      { service_name = "destination", plan_name = "lite" },
      { service_name = "destination", plan_name = "lite" },
    ]
  }

  expect_failures = [var.entitlements]
}
