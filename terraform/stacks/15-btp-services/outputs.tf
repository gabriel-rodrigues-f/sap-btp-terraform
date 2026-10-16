output "deployer" {
  description = "Usuário autenticado neste apply (precisa ser o mesmo do stack 10)."
  value       = data.btp_whoami.deployer.email
}

output "ias_host" {
  description = "Tenant do SAP Cloud Identity Services."
  value       = module.identity.ias_host
}

output "ias_admin_console" {
  description = "Console de administração do IAS (ative a conta pelo e-mail recebido)."
  value       = module.identity.ias_admin_console
}

output "ias_origin" {
  description = "Origin key do trust com o IAS."
  value       = module.identity.origin
}

output "subscriptions" {
  description = "URL de acesso de cada aplicação."
  value       = module.apps.subscriptions
}

output "app_role_assignments" {
  description = "Role collections atribuídas aos usuários do IAS (app|role collection|usuário)."
  value       = module.apps.role_assignments
}

output "service_instances" {
  description = "Instâncias de plataforma (Service Manager)."
  value       = module.platform_services.service_instances
}

output "service_keys" {
  description = "Service keys de plataforma (sem credenciais)."
  value       = module.platform_services.service_keys
}
