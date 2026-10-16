output "subscriptions" {
  description = "URL de acesso de cada aplicação."
  value       = { for k, s in btp_subaccount_subscription.this : k => s.subscription_url }
}

output "role_assignments" {
  description = "Atribuições feitas, no formato app|role collection|usuário."
  value       = keys(btp_subaccount_role_collection_assignment.this)
}
