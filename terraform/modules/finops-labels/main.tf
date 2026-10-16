#
# Taxonomia ÚNICA de labels de FinOps, traduzida para os dois formatos do BTP:
#
#   BTP (directory, subaccount, instâncias e bindings): map(set(string))
#   Cloud Foundry (org, space, instâncias e service keys): map(string) + annotations
#
# Um lugar só para definir as chaves = relatórios de custo que agrupam certo.
#

locals {
  cf_label_value_regex = "^[A-Za-z0-9]([A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?$"

  # Chaves que TODO recurso de um ambiente precisa ter. O Ansible usa esta
  # mesma lista para auditar o que existe de fato no Cloud Foundry.
  required_keys = [
    "cost-center",
    "business-unit",
    "workload",
    "environment",
    "region",
    "owner",
    "criticality",
    "data-classification",
    "managed-by",
  ]

  environment_labels = merge(var.extra, {
    "cost-center"         = var.cost_center
    "business-unit"       = var.business_unit
    "workload"            = var.workload
    "environment"         = var.environment
    "region"              = var.region
    "owner"               = var.owner
    "criticality"         = var.criticality
    "data-classification" = var.data_classification
    "managed-by"          = "terraform"
    "iac-repository"      = var.iac_repository
  })

  # A API do BTP aceita no MÁXIMO 10 chaves de label por recurso. Ficam fora
  # do lado BTP as que já são atributos nativos do objeto (região do
  # subaccount) ou só servem ao Cloud Foundry; labels extras vão só para o CF.
  # Assim sobra espaço para 1 chave específica do recurso (ex.: consumer).
  btp_excluded = ["region", "iac-repository"]

  btp_labels = merge(
    { for k, v in local.environment_labels : k => toset([v]) if !contains(local.btp_excluded, k) && !contains(keys(var.extra), k) },
    { "owner-contact" = toset([var.owner_contact]) },
  )

  # O directory é da unidade de negócio inteira: não tem workload, ambiente nem criticidade.
  btp_directory_labels = {
    for k, v in local.btp_labels : k => v
    if !contains(["workload", "environment", "criticality", "data-classification"], k)
  }
}

check "cf_label_values" {
  assert {
    condition     = alltrue([for v in values(local.environment_labels) : can(regex(local.cf_label_value_regex, v))])
    error_message = "Algum valor de label não segue a regra do Cloud Foundry (até 63 caracteres, alfanumérico, -, _ ou .)."
  }
}
