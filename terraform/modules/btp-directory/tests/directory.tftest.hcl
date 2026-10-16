mock_provider "btp" {}

variables {
  name      = "corporate-it"
  subdomain = "corporate-it-203d9eeb"
  labels    = { "cost-center" = ["cc-1001"] }

  entitlements = [
    { service_name = "destination", plan_name = "lite" },
    { service_name = "cloudfoundry", plan_name = "trial" },
  ]

  role_collection_assignments = {
    "Directory Administrator" = ["ana@example.com"]
    "Directory Viewer"        = ["bia@example.com", "caio@example.com"]
  }
}

run "directory_com_cota_e_permissoes" {
  command = plan

  assert {
    condition     = btp_directory.this.features == toset(["DEFAULT", "ENTITLEMENTS", "AUTHORIZATIONS"])
    error_message = "O directory precisa dos três features para distribuir cota e ter permissões próprias."
  }

  assert {
    condition     = length(btp_directory.this.labels) == 1 && btp_directory.this.labels["cost-center"] == toset(["cc-1001"])
    error_message = "Labels de FinOps devem ser aplicadas como recebidas."
  }

  assert {
    condition     = toset(keys(btp_directory_entitlement.this)) == toset(["destination/lite", "cloudfoundry/trial"])
    error_message = "Entitlements indexados por service/plan."
  }

  assert {
    condition     = length(btp_directory_role_collection_assignment.this) == 3
    error_message = "Um assignment por usuário e role collection."
  }
}

run "rejeita_role_collection_inexistente_no_directory" {
  command = plan

  variables {
    role_collection_assignments = { "Subaccount Administrator" = ["ana@example.com"] }
  }

  expect_failures = [var.role_collection_assignments]
}

run "rejeita_mais_de_10_labels" {
  command = plan

  variables {
    labels = { k0 = ["v"], k1 = ["v"], k2 = ["v"], k3 = ["v"], k4 = ["v"], k5 = ["v"], k6 = ["v"], k7 = ["v"], k8 = ["v"], k9 = ["v"], k10 = ["v"] }
  }

  expect_failures = [var.labels]
}
