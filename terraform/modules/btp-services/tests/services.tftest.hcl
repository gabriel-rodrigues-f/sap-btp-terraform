mock_provider "btp" {}

variables {
  subaccount_id = "00000000-0000-0000-0000-000000000000"
  labels        = { "cost-center" = ["cc-1001"] }

  subscriptions = [
    { app_name = "feature-flags-dashboard", plan_name = "dashboard" },
  ]

  service_instances = {
    audit = {
      name     = "audit-application-integration-qa-us10-001"
      offering = "auditlog-management"
      plan     = "default"
      keys     = ["siem", "cicd"]
    }
    sm = {
      name     = "sm-application-integration-qa-us10-001"
      offering = "service-manager"
      plan     = "subaccount-audit"
    }
  }
}

run "instancias_com_labels_de_finops" {
  command = plan

  assert {
    condition     = length(btp_subaccount_service_instance.this["audit"].labels) == 1 && btp_subaccount_service_instance.this["audit"].labels["cost-center"] == toset(["cc-1001"])
    error_message = "Instância recebe as labels de FinOps (serviço e plano já são atributos nativos)."
  }
}

run "uma_service_key_por_consumidor" {
  command = plan

  assert {
    condition     = toset(keys(btp_subaccount_service_binding.this)) == toset(["audit/siem", "audit/cicd"])
    error_message = "Uma key por instância/consumidor; instâncias sem keys não geram binding."
  }

  assert {
    condition     = btp_subaccount_service_binding.this["audit/siem"].name == "sk-siem"
    error_message = "Nome da key deve ser sk-<consumidor>."
  }

  assert {
    condition     = btp_subaccount_service_binding.this["audit/cicd"].labels["consumer"] == toset(["cicd"])
    error_message = "A key deve identificar o consumidor por label."
  }
}

run "assinatura_indexada_por_app_e_plano" {
  command = plan

  assert {
    condition     = contains(keys(btp_subaccount_subscription.this), "feature-flags-dashboard/dashboard")
    error_message = "Assinatura indexada por app/plan."
  }
}

run "rejeita_consumidor_fora_do_padrao" {
  command = plan

  variables {
    service_instances = {
      audit = { name = "x", offering = "auditlog-management", plan = "default", keys = ["Time de Integração"] }
    }
  }

  expect_failures = [var.service_instances]
}

run "rejeita_mais_de_9_labels" {
  command = plan

  variables {
    labels = { k0 = ["v"], k1 = ["v"], k2 = ["v"], k3 = ["v"], k4 = ["v"], k5 = ["v"], k6 = ["v"], k7 = ["v"], k8 = ["v"], k9 = ["v"] }
  }

  expect_failures = [var.labels]
}
