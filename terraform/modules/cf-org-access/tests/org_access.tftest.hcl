mock_provider "cloudfoundry" {}

variables {
  org_id = "11111111-2222-3333-4444-555555555555"

  roles = {
    organization_manager         = ["deployer@example.com", "ana@example.com"]
    organization_user            = ["bia@example.com"]
    organization_auditor         = ["caio@example.com"]
    organization_billing_manager = ["caio@example.com"]
  }

  exclude_users = ["deployer@example.com"]
}

run "todo_mundo_vira_membro_exceto_o_deployer" {
  command = plan

  assert {
    condition     = toset(keys(cloudfoundry_org_role.member)) == toset(["ana@example.com", "bia@example.com", "caio@example.com"])
    error_message = "Cada usuário (sem repetição) vira organization_user, exceto o excluído."
  }
}

run "papeis_adicionais_sem_duplicar_member" {
  command = plan

  assert {
    condition = toset(keys(cloudfoundry_org_role.this)) == toset([
      "organization_manager|ana@example.com",
      "organization_auditor|caio@example.com",
      "organization_billing_manager|caio@example.com",
    ])
    error_message = "organization_user não deve ser repetido; o deployer fica de fora."
  }

  assert {
    condition     = cloudfoundry_org_role.this["organization_manager|ana@example.com"].origin == "sap.ids"
    error_message = "Origem padrão deve ser sap.ids."
  }
}

run "rejeita_papel_de_space_na_org" {
  command = plan

  variables {
    roles = { space_developer = ["ana@example.com"] }
  }

  expect_failures = [var.roles]
}
