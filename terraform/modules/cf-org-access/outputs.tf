output "org_id" {
  description = "GUID da org, liberado só depois que todos os papéis de org existirem."
  value       = var.org_id

  depends_on = [
    cloudfoundry_org_role.member,
    cloudfoundry_org_role.this,
  ]
}

output "assignments" {
  description = "Papéis atribuídos, no formato papel|usuário."
  value = concat(
    [for user in local.members : "organization_user|${user}"],
    keys(local.extra_roles),
  )
}
