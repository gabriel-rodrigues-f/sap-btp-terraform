# Nenhuma credencial no código. O provider resolve a autenticação por variáveis
# de ambiente, nesta ordem de preferência para esta POC:
#
#   1. Sessão do btp CLI (local, compatível com SAP Universal ID e 2FA):
#        btp login --sso
#        export USE_BTPCLI_SESSION=true     # o Makefile já exporta
#
#   2. Usuário técnico / S-user SEM Universal ID e sem 2FA (ex.: pipeline):
#        export BTP_USERNAME=... BTP_PASSWORD=...
#
#   3. CI/CD sem senha, via IdP customizado (SAP Cloud Identity Services) + OIDC:
#        export BTP_ASSERTION=<jwt> BTP_IDP=<tenant>.accounts.ondemand.com
#
# Detalhes e armadilhas em docs/02-autenticacao.md.
provider "btp" {
  globalaccount = var.globalaccount
}
