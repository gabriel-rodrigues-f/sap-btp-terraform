# Estes outputs são o CONTRATO entre camadas: o stack 20 e o Ansible
# consomem apenas o que está aqui, nunca recursos internos deste stack.

output "conventions" {
  description = "Entradas da convenção de nomes (o stack 20 recalcula os nomes com elas)."
  value = {
    business_unit = var.business_unit
    workload      = var.workload
    environment   = var.environment
    region        = var.region
    unique_suffix = local.unique_suffix
  }
}

output "names" {
  description = "Nomes gerados pela convenção."
  value = {
    directory  = module.naming.directory
    subaccount = module.naming.subaccount
    cf_org     = module.naming.cf_org
  }
}

output "labels" {
  description = "Labels de FinOps no formato do Cloud Foundry, annotations e chaves obrigatórias."
  value = {
    cf            = module.labels.cf
    cf_annotation = module.labels.cf_annotations
    required_keys = module.labels.required_keys
  }
}

output "access" {
  description = "Personas e o usuário que executa o Terraform (deployer)."
  value = {
    deployer        = data.btp_whoami.deployer.email
    platform_admins = var.access.platform_admins
    developers      = var.access.developers
    auditors        = var.access.auditors
    finops          = var.access.finops
  }
}

output "directory_id" {
  description = "ID do directory."
  value       = module.directory.id
}

output "subaccount_id" {
  description = "ID do subaccount."
  value       = module.subaccount.id
}

output "subscriptions" {
  description = "URL de acesso de cada assinatura SaaS."
  value       = module.services.subscriptions
}

output "service_instances" {
  description = "Instâncias no nível do subaccount (Service Manager)."
  value       = module.services.service_instances
}

output "service_keys" {
  description = "Service keys no nível do subaccount (sem credenciais)."
  value       = module.services.service_keys
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
