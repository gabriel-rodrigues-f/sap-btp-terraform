variables {
  cost_center   = "cc-1001"
  business_unit = "corporate-it"
  workload      = "application-integration"
  environment   = "qa"
  region        = "us10"
  owner         = "platform-team"
  owner_contact = "platform@example.com"
}

run "gera_os_dois_formatos" {
  command = plan

  assert {
    condition     = output.btp["cost-center"] == toset(["cc-1001"])
    error_message = "No BTP, cada label é um set de strings."
  }

  assert {
    condition     = output.cf["cost-center"] == "cc-1001"
    error_message = "No Cloud Foundry, cada label é uma string."
  }

  assert {
    condition     = output.cf["managed-by"] == "terraform"
    error_message = "managed-by deve ser fixo em terraform."
  }

  assert {
    condition     = alltrue([for k in output.required_keys : contains(keys(output.cf), k)])
    error_message = "Todas as chaves obrigatórias devem existir nas labels do CF."
  }
}

run "email_nunca_vira_label_no_cf" {
  command = plan

  assert {
    condition     = !contains(keys(output.cf), "owner-contact") && output.cf_annotations["owner-contact"] == "platform@example.com"
    error_message = "E-mail vai em annotation no CF (label não aceita @)."
  }

  assert {
    condition     = output.btp["owner-contact"] == toset(["platform@example.com"])
    error_message = "No BTP o e-mail pode ser label."
  }
}

run "directory_nao_carrega_ambiente" {
  command = plan

  assert {
    condition     = !contains(keys(output.btp_directory), "environment") && !contains(keys(output.btp_directory), "workload")
    error_message = "Directory é da unidade de negócio inteira: sem environment/workload."
  }

  assert {
    condition     = output.btp_directory["cost-center"] == toset(["cc-1001"])
    error_message = "Directory deve manter o centro de custo."
  }
}

run "extra_soma_as_labels_da_empresa" {
  command = plan

  variables {
    extra = { project = "s4-migration" }
  }

  assert {
    condition     = output.cf["project"] == "s4-migration"
    error_message = "Labels extras devem ser incluídas."
  }
}

run "rejeita_owner_com_email" {
  command = plan

  variables {
    owner = "platform@example.com"
  }

  expect_failures = [var.owner]
}

run "rejeita_criticidade_fora_da_lista" {
  command = plan

  variables {
    criticality = "urgente"
  }

  expect_failures = [var.criticality]
}
