# Testes unitários com provider MOCKADO: rodam offline, sem credenciais BTP.
# Validam a LÓGICA do módulo (chaves de for_each, validações, achatamento),
# não o comportamento da API. Execute com: terraform -chdir=<módulo> test

mock_provider "btp" {}

variables {
  name      = "application-integration-qa-us10"
  subdomain = "application-integration-qa-us10-203d9eeb"
  region    = "us10"
  labels    = { "cost-center" = ["cc-1001"], "environment" = ["qa"] }

  entitlements = [
    { service_name = "cloudfoundry", plan_name = "trial" },
    { service_name = "destination", plan_name = "lite" },
    { service_name = "APPLICATION_RUNTIME", plan_name = "MEMORY", amount = 1 },
  ]

  role_collection_assignments = {
    "Subaccount Administrator" = ["ana@example.com"]
    "Subaccount Viewer"        = ["bia@example.com", "caio@example.com"]
  }
}

run "subaccount_rotulado_e_nao_produtivo" {
  command = plan

  assert {
    condition     = btp_subaccount.this.labels["resource-type"] == toset(["subaccount"]) && btp_subaccount.this.labels["cost-center"] == toset(["cc-1001"])
    error_message = "Labels de FinOps + resource-type devem ser aplicadas."
  }

  assert {
    condition     = btp_subaccount.this.usage == "NOT_USED_FOR_PRODUCTION"
    error_message = "Por padrão o subaccount é marcado como não produtivo."
  }
}

run "entitlements_usam_chave_estavel" {
  command = plan

  assert {
    condition = toset(keys(btp_subaccount_entitlement.this)) == toset([
      "cloudfoundry/trial",
      "destination/lite",
      "APPLICATION_RUNTIME/MEMORY",
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
    condition     = contains(keys(btp_subaccount_role_collection_assignment.this), "Subaccount Viewer|caio@example.com")
    error_message = "Chave do assignment deve ser 'role collection|usuário'."
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
