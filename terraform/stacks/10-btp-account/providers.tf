# Autenticação básica (usuário/senha do SAP ID service), SEM credenciais no código.
# O provider lê as variáveis de ambiente:
#
#   export BTP_USERNAME="voce@exemplo.com"
#   read -rs BTP_PASSWORD && export BTP_PASSWORD     # não vai para o histórico
#
# Nunca declare variável Terraform para a senha: ela acabaria em tfvars, no
# histórico do shell ou no plano salvo. Outras opções (SSO, OIDC, X.509) e o
# aviso sobre SAP Universal ID estão em docs/02-autenticacao.md.
provider "btp" {
  globalaccount = var.globalaccount
}
