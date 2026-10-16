output "environment_instance_id" {
  description = "ID da instância de ambiente no BTP."
  value       = btp_subaccount_environment_instance.this.id
}

output "org_id" {
  description = "GUID da org Cloud Foundry (platform_id da instância de ambiente)."
  value       = btp_subaccount_environment_instance.this.platform_id
}

output "org_name" {
  description = "Nome da org Cloud Foundry."
  value       = lookup(local.environment_labels, "Org Name", var.org_name)
}

output "api_endpoint" {
  description = "Endpoint da API Cloud Foundry (use em `cf login -a`)."
  value       = lookup(local.environment_labels, "API Endpoint", null)

  precondition {
    condition     = lookup(local.environment_labels, "API Endpoint", null) != null
    error_message = "O ambiente foi criado, mas o broker não devolveu o 'API Endpoint' em labels. Verifique o estado da instância no cockpit."
  }
}
