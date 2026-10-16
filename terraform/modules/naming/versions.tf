terraform {
  # Módulo "puro": só calcula nomes, não cria recursos nem usa provider.
  # Por isso roda em qualquer stack e é trivial de testar.
  required_version = ">= 1.9.0"
}
