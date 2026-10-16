# 1. Pré-requisitos da conta trial e rede

## A conta trial em 6 fatos

1. **Duração**: até 90 dias no total. A conta é suspensa a cada 30 dias e pode
   ser estendida no cockpit. Ao fim dos 90 dias, ela é apagada, com tudo dentro.
   Por isso o código vive no git e o ambiente pode ser recriado a qualquer momento.
2. **Regiões**: a trial oferece `us10` (AWS, Virgínia) e `ap21` (Azure, Singapura).
   O padrão deste repositório é `us10`.
3. **Directories são suportados**, inclusive com os features ENTITLEMENTS e
   AUTHORIZATIONS. Isso dá cota e permissões próprias por directory.
4. **Subaccounts adicionais são permitidos**. Neles, o ambiente Cloud Foundry
   precisa ser habilitado explicitamente, com o entitlement `cloudfoundry/trial`.
5. **A maioria dos planos é ELASTIC ou APPLICATION**: não consome cota numérica e
   pode ir para vários subaccounts. É o caso de destination, xsuaa, connectivity,
   feature-flags, alert-notification, html5-apps-repo, application-logs,
   auditlog-management e service-manager. Todos os planos usados aqui são desse tipo.
6. **Memória do Cloud Foundry** (`APPLICATION_RUNTIME/MEMORY`) só é consumida por
   **apps em execução**. Instâncias, service keys e assinaturas não usam essa cota,
   e esta POC não implanta apps.

## Descobrir o que a sua conta tem

```bash
make login-btp     # login do btp CLI (pede a senha)
make discover      # subaccounts e entitlements (somente leitura)
btp list accounts/subscription --subaccount <id>        # nomes técnicos das apps SaaS
btp list security/role-collection --subaccount <id>     # role collections disponíveis
```

O valor de `globalaccount` no `terraform.tfvars` é o **subdomínio** (ex.:
`1a2b3c4dtrial-ga`), não o nome de exibição; aparece em `btp --info`.

O nome técnico de uma app SaaS pode ser diferente do nome do entitlement. Por
exemplo, o entitlement `SAPLaunchpad` vira a app `SAPLaunchpadSMS`. Use sempre o
nome que aparece em `btp list accounts/subscription`.

## Hosts que precisam estar liberados

Se a sua rede, proxy corporativo ou sandbox bloqueia saída para a internet,
libere estes hosts (todos em HTTPS/443):

| Host | Usado por | Para quê |
| --- | --- | --- |
| `registry.terraform.io` | Terraform | Descobrir versões dos providers |
| `github.com`, `release-assets.githubusercontent.com`, `objects.githubusercontent.com` | Terraform, `make setup` | Baixar os binários dos providers `SAP/btp` e `cloudfoundry`, e o tflint |
| `releases.hashicorp.com` | Terraform (opcional) | Baixar o próprio Terraform |
| `cli.btp.cloud.sap` | btp CLI e provider BTP | API de administração do BTP (todo `plan`/`apply` do stack 10) |
| `accounts.sap.com` | Navegador (opcional) | Login no cockpit e fluxo SSO; o login usuário/senha da POC não depende dele |
| `api.cf.us10-001.hana.ondemand.com` | cf CLI, provider CF | API do Cloud Foundry |
| `login.cf.us10-001.hana.ondemand.com`, `uaa.cf.us10-001.hana.ondemand.com` | cf CLI, provider CF | Tokens OAuth do Cloud Foundry (`cf auth` e provider CF) |
| `galaxy.ansible.com` | `make setup` | Baixar as coleções Ansible |
| `pypi.org`, `files.pythonhosted.org` | `make setup` (uv) | Instalar ansible-core, ansible-lint, yamllint |
| `checkpoint-api.hashicorp.com` | Terraform (opcional) | Aviso de versão nova; o Makefile desativa com `CHECKPOINT_DISABLE=1` |

Em `ap21`, troque `us10-001` por `ap21` nos hosts do Cloud Foundry. O endpoint
exato da sua org aparece no output `cf_api_url` do stack 10.

## Ferramentas

| Ferramenta | Versão testada | Instalação (macOS) |
| --- | --- | --- |
| Terraform | 1.12 (mínimo 1.9) | `brew install hashicorp/tap/terraform` |
| btp CLI | 2.90 | `brew install --cask btp` |
| cf CLI | 8.14 | `brew install cloudfoundry/tap/cf-cli@8` |
| uv | qualquer recente | `brew install uv` |

O Ansible **não** precisa estar instalado globalmente: `make setup` cria uma
`.venv` com `ansible-core`, `ansible-lint` e `yamllint` nas versões do
`requirements.txt`. É a mesma toolchain que o CI usa.

## Recursos que já existem na conta

O Terraform só gerencia o que **ele** criou. Directories, subaccounts e orgs que
já existem na sua conta (por exemplo, o subaccount trial original) não são
tocados. Para trazê-los para o Terraform, use um bloco `import`; veja
[docs/04](04-terraform-boas-praticas.md#importar-recursos-existentes).
