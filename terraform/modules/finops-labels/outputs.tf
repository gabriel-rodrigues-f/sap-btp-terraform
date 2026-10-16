output "required_keys" {
  description = "Chaves obrigatórias em todo recurso do ambiente (usadas também pela auditoria do Ansible)."
  value       = local.required_keys
}

output "btp" {
  description = "Labels no formato do BTP (map de set) para subaccount, instâncias e bindings. No máximo 9 chaves."
  value       = local.btp_labels

  precondition {
    condition     = length(local.btp_labels) <= 9
    error_message = "O BTP aceita até 10 chaves de label por recurso; o conjunto base deve deixar 1 livre para a chave do recurso."
  }
}

output "btp_directory" {
  description = "Labels do directory (nível unidade de negócio, sem workload/ambiente)."
  value       = local.btp_directory_labels
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
