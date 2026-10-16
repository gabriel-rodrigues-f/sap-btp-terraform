# 2. Autenticação

## Escolha desta POC: usuário e senha

Um único par de credenciais do SAP ID service, sempre por **variáveis de
ambiente**. Nada de senha em código, tfvars, group_vars ou argumento de linha
de comando.

| Quem usa | Variáveis que lê | De onde vêm |
| --- | --- | --- |
| Provider BTP (stack 10) | `BTP_USERNAME`, `BTP_PASSWORD` | Você exporta no terminal |
| Provider Cloud Foundry (stack 20) | `CF_USER`, `CF_PASSWORD` | O Makefile copia de `BTP_*` |
| cf CLI no Ansible (`cf auth`) | `CF_USERNAME`, `CF_PASSWORD` | `group_vars` lê de `BTP_*` |

## Regra de identidade: confira ANTES de autenticar

Se o seu computador tem credenciais de mais de uma conta SAP (ex.: uma conta
corporativa exportada no `~/.zshrc`), **toda aba nova de terminal herda essas
credenciais**. Antes de qualquer `plan`, `apply`, `configure` ou login:

```bash
echo "$BTP_USERNAME"      # tem que ser o usuário da conta-alvo
btp --info | grep User    # sessão do btp CLI
cf target | grep user     # sessão do cf CLI
```

O repositório reforça a regra com travas:

| Trava | O que barra |
| --- | --- |
| `make check-creds` (todo alvo de plan/apply/configure) | `BTP_USERNAME` diferente do primeiro `access.platform_admins` do tfvars |
| Pós-condição em `data "btp_whoami"` (stacks 10 e 15) | Terraform autenticado com usuário fora de `platform_admins` ou diferente de quem aplicou o stack 10 |
| Role `cf_target` (Ansible) | `cf auth` com usuário diferente do deployer |
| Makefile | `CF_USER`/`CF_PASSWORD` herdados do perfil: o stack 20 usa sempre `BTP_*` |

## Exportar as credenciais

```bash
export BTP_USERNAME="voce@exemplo.com"
read -rs BTP_PASSWORD && export BTP_PASSWORD   # digitação oculta, não entra no histórico
make check-creds
```

As variáveis valem só para aquele terminal. Para não digitar a senha toda vez,
guarde-a no Keychain do macOS:

```bash
security add-generic-password -a "$BTP_USERNAME" -s sap-btp -w    # pede a senha uma vez
export BTP_PASSWORD="$(security find-generic-password -a "$BTP_USERNAME" -s sap-btp -w)"
```

## Por que desse jeito

- **Sem variável Terraform para a senha.** Se existisse, a senha acabaria em
  `terraform.tfvars`, no histórico do shell ou num `tfplan` salvo.
  Os providers leem o ambiente sozinhos.
- **`read -rs` em vez de `export BTP_PASSWORD=...`.** O comando digitado fica no
  histórico do shell; a leitura oculta, não.
- **O `cf auth` recebe a senha por ambiente, não por argumento.** Argumentos
  aparecem em `ps` para qualquer usuário da máquina. A task ainda usa `no_log: true`.
- **O provider CF tem `api_url` fixo (vindo do stack 10).** O plan não depende de
  onde o cf CLI estava apontando.
- `*.tfstate` e `terraform.tfvars` estão no `.gitignore`. `gitleaks` (pre-commit)
  e `trivy` (CI) barram segredos versionados por engano.

## Limitações do fluxo usuário/senha

- **2FA não é suportado.** Se a conta tiver 2FA ativo, use uma das alternativas abaixo.
- **SAP Universal ID.** A documentação do provider avisa que esse fluxo não é
  compatível com Universal ID (SAP Note 3085908). Se aparecer `invalid credentials`
  com a senha certa, use o **ID do usuário** (P-user, `P0000000000`) no lugar do
  e-mail, com a senha desse usuário. O mesmo vale quando há mais de um usuário com o mesmo e-mail.

## Alternativa: SSO

Para contas com 2FA ou Universal ID sem senha de P-user:

| Camada | Login | Configuração |
| --- | --- | --- |
| BTP | `btp login --sso` | `export USE_BTPCLI_SESSION=true` (sem `BTP_USERNAME`/`BTP_PASSWORD`) |
| Cloud Foundry | `cf login --sso -a <api>` | `provider "cloudfoundry" {}` **sem** `api_url`: o provider passa a ler `~/.cf/config.json` |

## CI/CD

Em pipeline, use uma identidade técnica, nunca a sua:

| Opção | Como | Quando usar |
| --- | --- | --- |
| **Usuário técnico** num IdP customizado (SAP Cloud Identity Services), sem 2FA | Os mesmos `BTP_USERNAME`/`BTP_PASSWORD` + `BTP_IDP` (e `CF_ORIGIN`), vindos do cofre de segredos do pipeline | Simples; exige rotação de senha |
| **JWT Bearer Assertion + OIDC** do GitHub Actions | `BTP_ASSERTION` + `BTP_IDP` (BTP) e `CF_ASSERTION_TOKEN` (CF), com trust do IAS no emissor OIDC do GitHub | Sem segredo de longa duração; é o ideal |
| **Certificado X.509** do usuário técnico | `tls_client_certificate`, `tls_client_key`, `tls_idp_url` | Quando OIDC não é possível |

Referências:

- Provider BTP, seção *Authentication*: <https://registry.terraform.io/providers/SAP/btp/latest/docs>
- Provider Cloud Foundry: <https://registry.terraform.io/providers/cloudfoundry/cloudfoundry/latest/docs>
- *Bye-Bye Credentials* (OIDC + Terraform + BTP): <https://dev.to/vipinvkmenon/bye-bye-credentials-automate-btp-cloud-foundry-setup-with-terraform-using-github-actions-and-3m07>
