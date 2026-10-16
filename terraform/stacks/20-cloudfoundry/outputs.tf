# Contrato com o Ansible: o que ele precisa para completar a org e auditar labels.

output "cf_api_url" {
  description = "Endpoint da API Cloud Foundry (repassado do stack 10)."
  value       = local.account.cf_api_url
}

output "cf_org_id" {
  description = "GUID da org."
  value       = local.account.cf_org_id
}

output "cf_org_name" {
  description = "Nome da org."
  value       = local.account.cf_org_name
}

output "cf_org_metadata" {
  description = "Labels e annotations que a ORG deve ter. A org é criada pelo BTP, então o Ansible as aplica."
  value = {
    labels      = merge(local.account.labels.cf, { "resource-type" = "cf-org" })
    annotations = local.account.labels.cf_annotation
  }
}

output "required_label_keys" {
  description = "Chaves de label obrigatórias (auditadas pelo Ansible)."
  value       = local.account.labels.required_keys
}

output "spaces" {
  description = "Spaces com suas instâncias e service keys (sem credenciais)."
  value = {
    for name, s in module.space : name => {
      id                = s.id
      service_instances = s.service_instances
      service_keys      = s.service_keys
    }
  }
}

output "org_role_assignments" {
  description = "Papéis de org atribuídos pelo Terraform (o deployer já é Org Manager pelo BTP)."
  value       = module.org_access.assignments
}
