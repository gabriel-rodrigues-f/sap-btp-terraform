# Estes outputs são o CONTRATO entre camadas: o stack 20 e o Ansible
# consomem apenas o que está aqui, nunca recursos internos deste stack.

output "project" {
  description = "Nome do projeto."
  value       = var.project
}

output "stage" {
  description = "Estágio/ambiente."
  value       = var.stage
}

output "admins" {
  description = "Administradores (reaproveitados como membros do space no stack 20)."
  value       = var.admins
}

output "subaccount_id" {
  description = "ID do subaccount."
  value       = module.subaccount.id
}

output "subaccount_subdomain" {
  description = "Subdomínio do subaccount."
  value       = module.subaccount.subdomain
}

output "destinations" {
  description = "Destinations criadas no nível do subaccount."
  value       = module.subaccount.destinations
}

output "cf_api_url" {
  description = "Endpoint da API Cloud Foundry."
  value       = module.cloudfoundry.api_endpoint
}

output "cf_org_id" {
  description = "GUID da org Cloud Foundry."
  value       = module.cloudfoundry.org_id
}

output "cf_org_name" {
  description = "Nome da org Cloud Foundry."
  value       = module.cloudfoundry.org_name
}

output "next_step" {
  description = "Próximo passo: autenticar o cf CLI na org recém-criada."
  value       = "cf login --sso -a ${module.cloudfoundry.api_endpoint} -o ${module.cloudfoundry.org_name}"
}
