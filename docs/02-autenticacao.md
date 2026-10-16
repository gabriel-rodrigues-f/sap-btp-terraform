# 2. Autenticação: Universal ID, SSO e CI/CD

## O problema

A documentação oficial do provider `SAP/btp` avisa que o fluxo
usuário/senha **não é compatível com SAP Universal ID** (SAP Note 3085908) e
que **2FA não é suportado** nesse fluxo. Contas trial criadas com e-mail
pessoal costumam usar Universal ID. Portanto, `BTP_USERNAME`/`BTP_PASSWORD` não
funcionam para você, e o mesmo vale para `cf login` com senha.

## A solução local: reaproveitar a sessão SSO dos CLIs

| Camada | Login (no navegador) | Como o Terraform/Ansible reaproveita |
| --- | --- | --- |
| BTP (stack 10) | `btp login --sso` (`make login-btp`) | `USE_BTPCLI_SESSION=true` (o Makefile exporta) |
| Cloud Foundry (stack 20 e Ansible) | `cf login --sso` (`make login-cf`) | Bloco `provider "cloudfoundry" {}` **vazio** lê `~/.cf/config.json`; o Ansible usa o próprio cf CLI |

Dois detalhes que custam tempo se você não souber:

1. **O bloco do provider CF tem que ficar vazio.** Se você preencher só
   `api_url`, o provider passa a exigir `user`/`password` ou token e ignora a
   sessão do CLI. O endpoint vem da sessão (`cf login -a ...`).
2. **O `cf login` precisa apontar para a org nova.** Por isso `make login-cf`
   lê `cf_api_url` e `cf_org_name` dos outputs do stack 10. As roles
   `preflight` e `cf_target` do Ansible conferem a sessão e o endpoint antes de
   qualquer alteração.

As sessões expiram. Se aparecer `Unknown session` ou `token expired`, repita o login.

## Nenhum segredo no repositório

- Não existe variável Terraform de senha neste código.
- `terraform.tfvars` (com e-mails e IDs) está no `.gitignore`. Só os `.example` são versionados.
- `*.tfstate` está no `.gitignore`. O estado pode conter dados sensíveis.
- A task do Ansible que lê o token do cf CLI usa `no_log: true`.
- `gitleaks` (pre-commit) e `trivy` (CI) barram segredos por engano.

## E no CI/CD?

Sessão SSO é interativa, então não serve para pipeline. O caminho recomendado é:

| Opção | Como | Quando usar |
| --- | --- | --- |
| **Usuário técnico** num IdP customizado (SAP Cloud Identity Services), sem Universal ID e sem 2FA | `BTP_USERNAME`, `BTP_PASSWORD`, `BTP_IDP` e, no CF, `CF_USER`, `CF_PASSWORD`, `CF_ORIGIN`, vindos do cofre de segredos do pipeline | Simples; exige rotação de senha |
| **JWT Bearer Assertion + OIDC** do GitHub Actions | `BTP_ASSERTION` + `BTP_IDP` (BTP) e `assertion_token` (CF), com trust do IAS no emissor OIDC do GitHub | Sem nenhum segredo de longa duração; é o ideal |
| **Certificado X.509** do usuário técnico | `tls_client_certificate`, `tls_client_key`, `tls_idp_url` | Quando OIDC não é possível |

Referências:

- Provider BTP, seção *Authentication*: <https://registry.terraform.io/providers/SAP/btp/latest/docs>
- Provider Cloud Foundry: <https://registry.terraform.io/providers/cloudfoundry/cloudfoundry/latest/docs>
- *Bye-Bye Credentials* (OIDC + Terraform + BTP): <https://dev.to/vipinvkmenon/bye-bye-credentials-automate-btp-cloud-foundry-setup-with-terraform-using-github-actions-and-3m07>
