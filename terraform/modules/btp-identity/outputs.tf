output "ias_host" {
  description = "Host do tenant do IAS (ex.: abc123.trial-accounts.ondemand.com)."
  value       = local.ias_host
}

output "ias_admin_console" {
  description = "Console de administração do IAS."
  value       = "https://${local.ias_host}/admin"
}

output "origin" {
  description = "Origin key do trust: use em role collection assignments para usuários do IAS."
  value       = btp_subaccount_trust_configuration.ias.origin

  # Só libera o origin depois que o IAS virou o IdP padrão.
  depends_on = [btp_subaccount_security_settings.this]
}

output "subaccount_id" {
  description = "ID do subaccount, liberado só depois que o trust e o IdP padrão existem (use para ordenar assinaturas)."
  value       = var.subaccount_id

  depends_on = [btp_subaccount_security_settings.this]
}
