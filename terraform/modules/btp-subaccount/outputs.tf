output "id" {
  description = "ID do subaccount. Só fica disponível depois que entitlements e role collections forem aplicados."
  value       = btp_subaccount.this.id

  # Truque útil: quem consome este output passa a depender também dos
  # entitlements, SEM precisar de depends_on no nível do módulo (que adiaria
  # todos os data sources do módulo consumidor para o apply).
  depends_on = [
    btp_subaccount_entitlement.this,
    btp_subaccount_role_collection_assignment.this,
  ]
}

output "name" {
  description = "Nome de exibição do subaccount."
  value       = btp_subaccount.this.name
}

output "subdomain" {
  description = "Subdomínio do subaccount."
  value       = btp_subaccount.this.subdomain
}

output "region" {
  description = "Região do subaccount."
  value       = btp_subaccount.this.region
}

output "entitlements" {
  description = "Entitlements aplicados, indexados por service/plan."
  value       = { for k, e in btp_subaccount_entitlement.this : k => e.amount }
}

output "subscriptions" {
  description = "URL de cada assinatura SaaS, indexada por app/plan."
  value       = { for k, s in btp_subaccount_subscription.this : k => s.subscription_url }
}

output "destinations" {
  description = "Nomes das destinations criadas no nível do subaccount."
  value       = keys(btp_subaccount_destination_generic.this)
}
