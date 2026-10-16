output "service_instances" {
  description = "Instâncias criadas (sem credenciais), indexadas pela chave lógica."
  value = {
    for k, si in btp_subaccount_service_instance.this : k => {
      id       = si.id
      name     = si.name
      offering = var.service_instances[k].offering
      plan     = var.service_instances[k].plan
    }
  }
}

output "service_keys" {
  description = "Service keys criadas, por instância/consumidor. As credenciais ficam só no estado (sensível)."
  value = {
    for k, b in btp_subaccount_service_binding.this : k => {
      id   = b.id
      name = b.name
    }
  }
}
