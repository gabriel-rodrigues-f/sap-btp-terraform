# 5. Troubleshooting

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| `Unknown session. Please log in.` (btp CLI) | Sessão do btp CLI ausente ou expirada (só afeta `make discover` e comandos manuais) | `make login-btp` |
| Provider BTP ou `cf auth`: `invalid credentials` / `Credentials were rejected` | Senha errada, 2FA ativo ou usuário com SAP Universal ID | Confira a senha; com Universal ID use o ID do P-user no lugar do e-mail (SAP Note 3085908); com 2FA use a [alternativa SSO](02-autenticacao.md#alternativa-sso) |
| Entitlement `APPLICATION_RUNTIME` falha por cota | Os 4 GB da trial estão no subaccount `trial` | [Liberar memória](01-pre-requisitos-trial.md#liberar-memória-cloud-foundry) |
| `subdomain ... already exists` / org name taken | Nome já usado na região (por você ou por outro cliente) | Mude `project` ou `stage` no tfvars |
| Ambiente CF falha com plano inválido | Plano `trial` só existe em conta trial | Em conta paga use `cf_environment_plan = "standard"`; confira com `btp list accounts/available-environment --subaccount <id>` |
| `Unable to create CF Client due to missing values` | `CF_USER`/`CF_PASSWORD` vazias (terraform rodado direto, sem o Makefile) | Use `make space-plan` ou exporte `CF_USER` e `CF_PASSWORD` |
| `cloudfoundry_space_role`: usuário não encontrado | Usuário nunca logou no Cloud Foundry desta região (não existe no UAA) | Peça para a pessoa fazer `cf login` uma vez, ou use `user_origin` correto se for IdP customizado |
| `Exporte as credenciais antes` / `Credenciais ausentes` | `BTP_USERNAME`/`BTP_PASSWORD` não exportadas neste terminal | [Exporte as credenciais](02-autenticacao.md#exportar-as-credenciais) |
| `cf push` falha no staging | Erro na app ou no buildpack | `cf logs hello-btp --recent`; com o provider CF, `ENABLE_CF_APP_LOG_TRACE=true` |
| Smoke test: `/destination` retorna 404 | Nome em `app_destination_name` diferente da chave em `destinations` (stack 10) | Alinhe os nomes; `terraform output destinations` mostra o que existe |
| Smoke test: `/destination` retorna 503 | Serviço `destination` não ligado à app | Confira `service_instances` no stack 20 e rode `make deploy` |
| `terraform destroy` do stack 20 falha | Apps ainda no space | Rode `make down` (remove a app antes) ou `ansible-playbook playbooks/teardown.yml` |
| Todo `plan` mostra mudança | Valor volátil (`timestamp()`) ou atributo alterado pelo BTP | `make drift` mostra o que mudou fora; remova valores voláteis |
| Trial "suspended" | 30 dias sem extensão | Estenda no cockpit da trial |

## Comandos úteis de diagnóstico

```bash
btp --info                                   # usuário, global account e config em uso
btp list accounts/subaccount
btp list accounts/entitlement --subaccount <id>
terraform -chdir=terraform/stacks/10-btp-subaccount output
cf target && cf services && cf apps
cf curl "/v3/apps?names=hello-btp" | jq '.resources[0].metadata'
TF_LOG=DEBUG terraform -chdir=terraform/stacks/20-cf-space plan   # log detalhado
```
