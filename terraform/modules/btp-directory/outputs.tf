output "id" {
  description = "ID do directory. Disponível só depois que a cota e as permissões foram aplicadas."
  value       = btp_directory.this.id

  # Quem cria subaccount dentro do directory herda esta dependência: sem a cota
  # no directory, o entitlement do subaccount falharia.
  depends_on = [
    btp_directory_entitlement.this,
    btp_directory_role_collection_assignment.this,
  ]
}

output "name" {
  description = "Nome do directory."
  value       = btp_directory.this.name
}

output "entitlements" {
  description = "Planos liberados para o directory."
  value       = keys(btp_directory_entitlement.this)
}
