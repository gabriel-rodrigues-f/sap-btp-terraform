# O endpoint vem do stack 10 (contrato via outputs); as credenciais vêm do
# ambiente, nunca do código:
#
#   CF_USER / CF_PASSWORD   (o Makefile preenche a partir de BTP_USERNAME / BTP_PASSWORD)
#   CF_ORIGIN               (opcional; só para IdP customizado)
#
# Com api_url definido aqui, o provider NÃO usa a sessão do cf CLI
# (~/.cf/config.json): o plan é reproduzível e independe de onde o CLI aponta.
provider "cloudfoundry" {
  api_url = local.account.cf_api_url
}
