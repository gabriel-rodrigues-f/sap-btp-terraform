# Contrato com o Ansible: tudo o que o deploy precisa saber sobre o "onde".

output "cf_api_url" {
  description = "Endpoint da API Cloud Foundry (repassado do stack 10)."
  value       = local.account.cf_api_url
}

output "cf_org_name" {
  description = "Nome da org (repassado do stack 10)."
  value       = local.account.cf_org_name
}

output "cf_space_id" {
  description = "GUID do space."
  value       = module.space.id
}

output "cf_space_name" {
  description = "Nome do space."
  value       = module.space.name
}

output "service_instances" {
  description = "Instâncias de serviço disponíveis para bind (nome => id/offering/plan)."
  value       = module.space.service_instances
}

output "destinations" {
  description = "Destinations do subaccount (repassado do stack 10) que a aplicação pode consultar."
  value       = local.account.destinations
}
