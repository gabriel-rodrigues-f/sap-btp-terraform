# O provider mockado gera strings aleatórias para atributos computados.
# Como `labels` precisa ser um JSON válido, usamos override_resource para
# fixar o valor que o broker real devolveria.

mock_provider "btp" {}

variables {
  subaccount_id = "00000000-0000-0000-0000-000000000000"
  org_name      = "acme-btp-poc-dev"
  plan_name     = "trial"
}

run "extrai_endpoint_e_org_dos_labels" {
  command = apply

  override_resource {
    target = btp_subaccount_environment_instance.this
    values = {
      platform_id = "11111111-2222-3333-4444-555555555555"
      labels      = "{\"API Endpoint\":\"https://api.cf.us10-001.hana.ondemand.com\",\"Org Name\":\"acme-btp-poc-dev\",\"Org ID\":\"11111111-2222-3333-4444-555555555555\"}"
    }
  }

  assert {
    condition     = output.api_endpoint == "https://api.cf.us10-001.hana.ondemand.com"
    error_message = "api_endpoint deve vir do label 'API Endpoint'."
  }

  assert {
    condition     = output.org_id == "11111111-2222-3333-4444-555555555555"
    error_message = "org_id deve ser o platform_id da instância."
  }

  assert {
    condition     = jsondecode(btp_subaccount_environment_instance.this.parameters).instance_name == var.org_name
    error_message = "instance_name deve ser o nome da org."
  }
}

run "falha_se_broker_nao_devolver_endpoint" {
  command = apply

  # Estado isolado: sem isso, o recurso criado no run anterior seria reaproveitado
  # (nada mudou na config) e o override abaixo nunca seria aplicado.
  state_key = "sem_endpoint"

  override_resource {
    target = btp_subaccount_environment_instance.this
    values = {
      labels = "{}"
    }
  }

  expect_failures = [output.api_endpoint]
}
