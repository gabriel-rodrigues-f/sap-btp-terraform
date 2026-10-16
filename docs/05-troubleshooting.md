# 5. Troubleshooting

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| `Unknown session. Please log in.` (btp) | Sessão do btp CLI expirou | `make login-btp` |
| Provider BTP: `invalid credentials` | Usuário/senha com SAP Universal ID | Não use `BTP_USERNAME`/`BTP_PASSWORD`; use `make login-btp` (sessão SSO) |
| Provider BTP não encontra a sessão, mesmo logado | Caminho do config do btp CLI diferente do padrão | `export BTPCLI_CONFIG_PATH="$(btp --info \| sed -n 's/^Configuration: *//p')"` |
| Entitlement `APPLICATION_RUNTIME` falha por cota | Os 4 GB da trial estão no subaccount `trial` | [Liberar memória](01-pre-requisitos-trial.md#liberar-memória-cloud-foundry) |
| `subdomain ... already exists` / org name taken | Nome já usado na região (por você ou por outro cliente) | Mude `project` ou `stage` no tfvars |
| Ambiente CF falha com plano inválido | Plano `trial` só existe em conta trial | Em conta paga use `cf_environment_plan = "standard"`; confira com `btp list accounts/available-environment --subaccount <id>` |
| `Unable to create CF Client due to missing values` | Sem sessão do cf CLI, ou `api_url` preenchido no provider | `make login-cf` e mantenha `provider "cloudfoundry" {}` vazio |
| `cloudfoundry_space_role`: usuário não encontrado | Usuário nunca logou no Cloud Foundry desta região (não existe no UAA) | Peça para a pessoa fazer `cf login --sso` uma vez, ou use `user_origin` correto se for IdP customizado |
| Ansible: `O cf CLI aponta para outro endpoint` | `cf login` feito em outra região/org | `make login-cf` |
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
