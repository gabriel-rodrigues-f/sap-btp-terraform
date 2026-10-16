output "required_keys" {
  description = "Chaves obrigatórias em todo recurso do ambiente (usadas também pela auditoria do Ansible)."
  value       = local.required_keys
}

output "btp" {
  description = "Labels no formato do BTP (map de set) para subaccount, instâncias e bindings."
  value = merge(
    { for k, v in local.environment_labels : k => toset([v]) },
    { "owner-contact" = toset([var.owner_contact]) },
  )
}

output "btp_directory" {
  description = "Labels do directory (nível unidade de negócio, sem workload/ambiente)."
  value = merge(
    { for k, v in local.directory_labels : k => toset([v]) },
    { "owner-contact" = toset([var.owner_contact]) },
  )
}

output "cf" {
  description = "Labels no formato do Cloud Foundry (map de string)."
  value       = local.environment_labels
}

output "cf_annotations" {
  description = "Annotations do Cloud Foundry: dados úteis que não cabem na regra de label (e-mail, URL)."
  value = {
    "owner-contact"      = var.owner_contact
    "iac-repository-url" = var.iac_repository_url
  }
}
