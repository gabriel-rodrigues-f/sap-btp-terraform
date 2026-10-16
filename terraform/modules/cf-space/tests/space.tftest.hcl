mock_provider "cloudfoundry" {}

variables {
  org_id = "11111111-2222-3333-4444-555555555555"
  name   = "dev"

  roles = {
    space_manager   = ["ana@example.com"]
    space_developer = ["ana@example.com", "bia@example.com"]
  }

  service_instances = {
    "btp-poc-destination" = { offering = "destination", plan = "lite" }
    "btp-poc-xsuaa" = {
      offering   = "xsuaa"
      plan       = "application"
      parameters = jsonencode({ xsappname = "btp-poc", "tenant-mode" = "dedicated" })
    }
  }
}

run "ssh_desligado_e_sem_labels_por_padrao" {
  command = plan

  assert {
    condition     = cloudfoundry_space.this.allow_ssh == false
    error_message = "allow_ssh deve ser false por padrão."
  }

  assert {
    condition     = cloudfoundry_space.this.labels == null
    error_message = "Sem labels, o atributo deve ficar nulo (o provider rejeita map vazio)."
  }
}

run "um_role_por_usuario_e_papel" {
  command = plan

  assert {
    condition     = length(cloudfoundry_space_role.this) == 3
    error_message = "Esperado 3 atribuições (1 manager + 2 developers)."
  }

  assert {
    condition     = cloudfoundry_space_role.this["space_developer|bia@example.com"].origin == "sap.ids"
    error_message = "Origem padrão deve ser sap.ids."
  }
}

run "parametros_json_sao_repassados" {
  command = plan

  assert {
    condition     = cloudfoundry_service_instance.this["btp-poc-destination"].parameters == null
    error_message = "Sem parameters, o atributo deve ficar nulo."
  }

  assert {
    condition     = jsondecode(cloudfoundry_service_instance.this["btp-poc-xsuaa"].parameters).xsappname == "btp-poc"
    error_message = "parameters deve chegar intacto ao service broker."
  }
}

run "rejeita_papel_invalido" {
  command = plan

  variables {
    roles = { org_manager = ["ana@example.com"] }
  }

  expect_failures = [var.roles]
}

run "rejeita_parametros_que_nao_sao_json" {
  command = plan

  variables {
    service_instances = {
      quebrado = { offering = "destination", plan = "lite", parameters = "{nao-e-json" }
    }
  }

  expect_failures = [var.service_instances]
}
