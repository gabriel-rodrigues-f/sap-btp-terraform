# 1. Pré-requisitos da conta trial e rede

## A conta trial em 5 fatos

1. **Duração**: até 90 dias no total. A conta é suspensa a cada 30 dias e pode
   ser estendida no cockpit. Ao fim dos 90 dias, ela é apagada, com tudo dentro.
   Por isso o código vive no git e o ambiente pode ser recriado a qualquer momento.
2. **Regiões**: a trial oferece `us10` (AWS, Virgínia) e `ap21` (Azure, Singapura).
   O padrão deste repositório é `us10`.
3. **Estrutura inicial**: um global account (subdomínio terminando em `-ga`) com
   um subaccount `trial` que já tem uma org Cloud Foundry.
4. **Subaccounts adicionais são permitidos**. Neles, a org Cloud Foundry precisa
   ser criada explicitamente, e é isso que o stack 10 faz.
5. **Cota de memória Cloud Foundry**: a trial tem 4 GB (`APPLICATION_RUNTIME` /
   `MEMORY`), **todos atribuídos ao subaccount `trial`**. Um subaccount novo só
   recebe memória se você liberar parte dela antes.

## Descobrir os dados do seu global account

```bash
btp login                # ou: make login-btp (pede usuário e senha)
btp --info               # "Current target" mostra o subdomínio do global account
make discover            # subaccounts + entitlements (somente leitura)
```

O valor que vai em `globalaccount` no `terraform.tfvars` é o **subdomínio**
(ex.: `1a2b3c4dtrial-ga`), não o nome de exibição.

## Liberar memória Cloud Foundry

O stack 10 pede `amount = 1` (1 GB) de `APPLICATION_RUNTIME/MEMORY` para o
subaccount novo. Reduza a cota do subaccount `trial` de 4 para 3:

```bash
# 1. ID do subaccount "trial"
btp list accounts/subaccount

# 2. Reduzir a cota dele (libera 1 GB no global account)
btp assign accounts/entitlement --to-subaccount <ID_DO_SUBACCOUNT_TRIAL> \
  --for-service APPLICATION_RUNTIME --plan MEMORY --amount 3
```

> Se apps no subaccount `trial` já usam mais de 3 GB, a redução falha. Pare ou
> reduza essas apps antes. Também é possível fazer isso no cockpit, em
> *Entitlements* do subaccount `trial`.

Por que essa etapa fica fora do Terraform? O subaccount `trial` não foi criado
por este código. Se o Terraform passasse a gerenciá-lo (via `import`), um
`destroy` poderia apagá-lo. Mudanças pontuais em recursos que você não possui
ficam melhor como passo manual documentado. O [docs/03](03-terraform-boas-praticas.md#importar-recursos-existentes)
mostra como importar com segurança, se um dia fizer sentido.

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
| `*.cfapps.us10-001.hana.ondemand.com` | Ansible (smoke test) | Acessar a app implantada |
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
| Node.js | 22 (só para rodar a app localmente) | `brew install node@22` |

O Ansible **não** precisa estar instalado globalmente: `make setup` cria uma
`.venv` com `ansible-core`, `ansible-lint` e `yamllint` nas versões do
`requirements.txt`. É a mesma toolchain que o CI usa.
