# Mesma autenticação do stack 10: usuário/senha do SAP ID service por variáveis
# de ambiente (BTP_USERNAME / BTP_PASSWORD). Veja docs/02-autenticacao.md.
provider "btp" {
  globalaccount = local.account.conventions.globalaccount
}
