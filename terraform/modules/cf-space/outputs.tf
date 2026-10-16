output "id" {
  description = "GUID do space."
  value       = cloudfoundry_space.this.id

  # Garante que quem usa o space (ex.: Ansible fazendo cf push) só o recebe
  # depois que os papéis existirem; sem space_developer o push falha.
  depends_on = [cloudfoundry_space_role.this]
}

output "name" {
  description = "Nome do space."
  value       = cloudfoundry_space.this.name
}

output "service_instances" {
  description = "Instâncias de serviço criadas, indexadas pelo nome."
  value = {
    for name, si in cloudfoundry_service_instance.this : name => {
      id       = si.id
      offering = var.service_instances[name].offering
      plan     = var.service_instances[name].plan
    }
  }
}
