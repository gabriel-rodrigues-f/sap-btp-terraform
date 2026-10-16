mock_provider "cloudfoundry" {}

variables {
  org_id      = "11111111-2222-3333-4444-555555555555"
  name        = "integration"
  labels      = { "cost-center" = "cc-1001", "environment" = "qa" }
  annotations = { "owner-contact" = "platform@example.com" }

  roles = {
    space_manager   = ["ana@example.com"]
    space_developer = ["ana@example.com", "bia@example.com"]
  }

  service_instances = {
    destination = {
      name     = "dest-application-integration-qa-us10-001"
      offering = "destination"
      plan     = "lite"
      keys     = ["cicd", "integration-suite"]
    }
    xsuaa = {
      name       = "uaa-application-integration-qa-us10-001"
      offering   = "xsuaa"
      plan       = "application"
      parameters = "{\"xsappname\":\"uaa-application-integration-qa-us10-001\",\"tenant-mode\":\"dedicated\"}"
    }
  }
}

run "space_rotulado_e_sem_ssh" {
  command = plan

  assert {
    condition     = cloudfoundry_space.this.allow_ssh == false
    error_message = "allow_ssh deve ser false por padrão."
  }

  assert {
    condition     = cloudfoundry_space.this.labels["resource-type"] == "cf-space" && cloudfoundry_space.this.labels["cost-center"] == "cc-1001"
    error_message = "Space deve receber as labels de FinOps + resource-type."
  }

  assert {
    condition     = cloudfoundry_space.this.annotations["owner-contact"] == "platform@example.com"
    error_message = "Annotations devem ser repassadas."
  }
}

run "um_role_por_usuario_e_papel" {
  command = plan

  assert {
    condition     = length(cloudfoundry_space_role.this) == 3
    error_message = "Esperado 3 atribuições (1 manager + 2 developers)."
  }
}

run "instancias_e_keys_rotuladas" {
  command = plan

  assert {
    condition     = cloudfoundry_service_instance.this["destination"].labels["service"] == "destination" && cloudfoundry_service_instance.this["destination"].labels["plan"] == "lite"
    error_message = "Instância deve carregar service e plan."
  }

  assert {
    condition     = toset(keys(cloudfoundry_service_credential_binding.key)) == toset(["destination/cicd", "destination/integration-suite"])
    error_message = "Uma key por consumidor; xsuaa sem keys não gera binding."
  }

  assert {
    condition     = cloudfoundry_service_credential_binding.key["destination/cicd"].name == "sk-cicd" && cloudfoundry_service_credential_binding.key["destination/cicd"].labels["consumer"] == "cicd"
    error_message = "Key: nome sk-<consumidor> e label consumer."
  }

  assert {
    condition     = jsondecode(cloudfoundry_service_instance.this["xsuaa"].parameters).xsappname == "uaa-application-integration-qa-us10-001"
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
      quebrado = { name = "x", offering = "destination", plan = "lite", parameters = "{nao-e-json" }
    }
  }

  expect_failures = [var.service_instances]
}
