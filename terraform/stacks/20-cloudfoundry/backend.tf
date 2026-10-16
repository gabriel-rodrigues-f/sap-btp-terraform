terraform {
  # Um estado POR STACK: menor raio de impacto, plans mais rápidos e permissões
  # separadas (quem mexe em space não precisa poder destruir o subaccount).
  # Para backend remoto, veja os exemplos em ../10-btp-account/backend.tf.
  backend "local" {
    path = "terraform.tfstate"
  }
}
