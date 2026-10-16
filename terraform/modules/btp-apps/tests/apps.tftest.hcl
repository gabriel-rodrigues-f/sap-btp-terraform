mock_provider "btp" {}

variables {
  subaccount_id = "00000000-0000-0000-0000-000000000000"
  users         = ["ana@example.com"]
  origin        = "sap.custom"

  subscriptions = {
    bas = {
      app_name         = "sapappstudiotrial"
      plan             = "trial"
      role_collections = ["Business_Application_Studio_Administrator", "Business_Application_Studio_Developer"]
    }
    integration-suite = {
      app_name         = "it-cpitrial06-prov"
      plan             = "trial"
      role_collections = ["Integration_Provisioner"]
    }
    feature-flags = {
      app_name = "feature-flags-dashboard"
      plan     = "dashboard"
    }
    build-apps = {
      app_name = "sap-appgyver-ee"
      plan     = "free"
      custom_role_collections = {
        BuildAppsAdmin = { role_templates = ["BuildAppsAdmin"], app_prefixes = ["appgyver-xsuaa!"] }
      }
    }
  }
}

# O filtro de roles por prefixo do app id depende do data source
# btp_subaccount_roles, cujo atributo aninhado não aceita override no
# `terraform test` (1.12); ele é validado no apply real.
run "role_collection_customizada_planejada_e_atribuida" {
  command = plan

  assert {
    condition     = btp_subaccount_role_collection.custom["BuildAppsAdmin"].name == "BuildAppsAdmin"
    error_message = "A role collection customizada deve ser criada com o nome pedido."
  }

  assert {
    condition     = contains(keys(btp_subaccount_role_collection_assignment.this), "build-apps|BuildAppsAdmin|ana@example.com")
    error_message = "A role collection customizada também é atribuída ao usuário."
  }
}

run "uma_atribuicao_por_app_role_e_usuario" {
  command = plan

  assert {
    condition = toset(keys(btp_subaccount_role_collection_assignment.this)) == toset([
      "bas|Business_Application_Studio_Administrator|ana@example.com",
      "bas|Business_Application_Studio_Developer|ana@example.com",
      "integration-suite|Integration_Provisioner|ana@example.com",
      "build-apps|BuildAppsAdmin|ana@example.com",
    ])
    error_message = "Atribuições devem ser app x role collection x usuário; app sem roles não gera nada."
  }

  assert {
    condition     = btp_subaccount_role_collection_assignment.this["integration-suite|Integration_Provisioner|ana@example.com"].origin == "sap.custom"
    error_message = "As roles vão para o usuário do IAS (origin do trust)."
  }
}

run "rejeita_parametros_que_nao_sao_json" {
  command = plan

  variables {
    subscriptions = { x = { app_name = "x", plan = "y", parameters = "{quebrado" } }
  }

  expect_failures = [var.subscriptions]
}
