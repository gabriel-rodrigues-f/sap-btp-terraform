output "base" {
  description = "Prefixo comum <workload>-<ambiente>-<região>."
  value       = local.base
}

output "directory" {
  description = "Nome do directory: a unidade de negócio, que agrupa seus workloads e ambientes."
  value       = var.business_unit
}

output "directory_subdomain" {
  description = "Subdomínio do directory (exigido quando o directory gerencia autorizações). Único na região."
  value       = "${var.business_unit}-${var.unique_suffix}"
}

output "subaccount" {
  description = "Nome de exibição do subaccount."
  value       = local.base
}

output "subaccount_subdomain" {
  description = "Subdomínio do subaccount: único na região e imutável."
  value       = "${local.base}-${var.unique_suffix}"

  precondition {
    condition     = length("${local.base}-${var.unique_suffix}") <= 63
    error_message = "O subdomínio passaria de 63 caracteres. Encurte o workload."
  }
}

output "cf_org" {
  description = "Nome da org Cloud Foundry: único no landscape inteiro, por isso leva o sufixo."
  value       = "${local.base}-${var.unique_suffix}"
}

output "service_instances" {
  description = "Nome de cada instância de serviço, pela chave lógica."
  value       = local.service_instances
}

output "abbreviations" {
  description = "Tabela de abreviações efetivamente usada (padrão + sobrescritas)."
  value       = local.abbreviations
}
