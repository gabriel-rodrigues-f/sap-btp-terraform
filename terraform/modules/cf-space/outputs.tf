output "id" {
  description = "GUID do space."
  value       = cloudfoundry_space.this.id

  depends_on = [cloudfoundry_space_role.this]
}

output "name" {
  description = "Nome do space."
  value       = cloudfoundry_space.this.name
}

output "service_instances" {
  description = "Instâncias criadas, indexadas pela chave lógica."
  value = {
    for k, si in cloudfoundry_service_instance.this : k => {
      id       = si.id
      name     = si.name
      offering = var.service_instances[k].offering
      plan     = var.service_instances[k].plan
    }
  }
}

output "service_keys" {
  description = "Service keys criadas, por instância/consumidor (sem credenciais)."
  value = {
    for k, b in cloudfoundry_service_credential_binding.key : k => {
      id   = b.id
      name = b.name
    }
  }
}
