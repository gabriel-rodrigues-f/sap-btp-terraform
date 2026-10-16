variables {
  business_unit = "corporate-it"
  workload      = "application-integration"
  environment   = "qa"
  region        = "us10"
  unique_suffix = "203d9eeb"

  service_instances = {
    destination = { offering = "destination" }
    xsuaa_api   = { offering = "xsuaa", instance = "002" }
    custom      = { offering = "meu-servico-novo" }
  }
}

run "gera_nomes_no_padrao_caf" {
  command = plan

  assert {
    condition     = output.subaccount == "application-integration-qa-us10"
    error_message = "Subaccount deve ser <workload>-<ambiente>-<região>."
  }

  assert {
    condition     = output.subaccount_subdomain == "application-integration-qa-us10-203d9eeb"
    error_message = "Subdomínio deve levar o sufixo único."
  }

  assert {
    condition     = output.directory == "corporate-it" && output.directory_subdomain == "corporate-it-203d9eeb"
    error_message = "Directory deve ser a unidade de negócio (com sufixo no subdomínio)."
  }

  assert {
    condition     = output.service_instances["destination"] == "dest-application-integration-qa-us10-001"
    error_message = "Instância deve ser <abreviação>-<base>-<nnn>."
  }

  assert {
    condition     = output.service_instances["xsuaa_api"] == "uaa-application-integration-qa-us10-002"
    error_message = "O número da instância deve ser respeitado."
  }

  assert {
    condition     = output.service_instances["custom"] == "meu-servico-novo-application-integration-qa-us10-001"
    error_message = "Serviço sem abreviação usa o próprio nome."
  }
}

run "abreviacao_pode_ser_sobrescrita" {
  command = plan

  variables {
    abbreviations = { "meu-servico-novo" = "msn" }
  }

  assert {
    condition     = output.service_instances["custom"] == "msn-application-integration-qa-us10-001"
    error_message = "Abreviações extras devem ter precedência."
  }
}

run "rejeita_ambiente_fora_da_lista" {
  command = plan

  variables {
    environment = "QA"
  }

  expect_failures = [var.environment]
}

run "rejeita_workload_fora_do_padrao" {
  command = plan

  variables {
    workload = "Application_Integration"
  }

  expect_failures = [var.workload]
}
