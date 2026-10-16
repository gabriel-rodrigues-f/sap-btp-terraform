# O bloco fica VAZIO de propósito.
#
# Sem atributos e sem variáveis CF_*, o provider usa a sessão do cf CLI
# (~/.cf/config.json): endpoint, token e refresh token. É o caminho que funciona
# com SAP Universal ID, porque o login acontece no navegador:
#
#   cf login --sso -a <cf_api_url do stack 10>     # make login-cf faz isso
#
# Atenção: se você preencher só `api_url` aqui, o provider passa a EXIGIR
# user/password ou token e ignora a sessão do CLI.
#
# Em pipeline, use um usuário técnico (sem Universal ID) por variáveis de ambiente:
#   CF_API_URL, CF_USER, CF_PASSWORD [, CF_ORIGIN]
provider "cloudfoundry" {}
