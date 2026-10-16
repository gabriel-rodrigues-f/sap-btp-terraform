# tflint pega o que o `terraform validate` não pega: variáveis sem tipo ou
# descrição, providers sem versão, declarações não usadas, nomes fora do padrão.
config {
  call_module_type = "local" # também inspeciona os módulos chamados pelos stacks
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}
