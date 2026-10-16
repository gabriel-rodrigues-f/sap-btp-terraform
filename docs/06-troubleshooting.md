# 6. Troubleshooting

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| `Exporte as credenciais antes` / `Credenciais ausentes` | `BTP_USERNAME`/`BTP_PASSWORD` não exportadas neste terminal | [Exporte as credenciais](02-autenticacao.md#exportar-as-credenciais) |
| Provider BTP ou `cf auth`: `invalid credentials` / `Credentials were rejected` | Senha errada, 2FA ativo ou usuário com SAP Universal ID | Confira a senha; com Universal ID use o ID do P-user no lugar do e-mail (SAP Note 3085908); com 2FA use a [alternativa SSO](02-autenticacao.md#alternativa-sso) |
| `Unknown session. Please log in.` (btp CLI) | Sessão do btp CLI ausente ou expirada (só afeta `make discover` e comandos manuais) | `make login-btp` |
| `subdomain ... already exists` / org name taken | Nome já usado na região (por você ou por outro cliente) | Mude `unique_suffix`, `workload` ou `environment` no tfvars |
| Entitlement do subaccount falha com "not entitled" / "quota" | O directory (feature ENTITLEMENTS) ainda não recebeu o plano | O módulo cria a cota do directory antes; confira se o plano está na lista `entitlements` e se há cota livre (`make discover`) |
| Plano de cota numérica falha | Cota já toda usada por outro subaccount (ex.: `jobscheduler/free`, `credstore/trial`) | Use planos ELASTIC ou mova cota com `btp assign accounts/entitlement` |
| Ambiente CF falha com plano inválido | Plano `trial` só existe em conta trial | Em conta paga use `cf_environment_plan = "standard"`; confira com `btp list accounts/available-environment --subaccount <id>` |
| Assinatura falha com app não encontrada | Nome técnico da app diferente do entitlement | Use o nome de `btp list accounts/subscription --subaccount <id>` |
| `Unable to create CF Client due to missing values` | `CF_USER`/`CF_PASSWORD` vazias (terraform rodado direto, sem o Makefile) | Use `make cf-plan` ou exporte `CF_USER` e `CF_PASSWORD` |
| `cloudfoundry_org_role`: role already exists / 422 | Papel criado fora do Terraform (cockpit) | Remova o papel manual ou importe-o; o deployer já é excluído automaticamente |
| `cloudfoundry_org_role`/`space_role`: usuário não encontrado | Usuário nunca logou no Cloud Foundry desta região (não existe no UAA) | Peça para a pessoa fazer `cf login` uma vez, ou use `user_origin` correto se for IdP customizado |
| Criação de instância CF retorna 403 | Usuário do Terraform sem `space_developer` | O stack 20 já dá esse papel ao deployer; confira `terraform output access` no stack 10 |
| `Provider produced inconsistent result after apply` em `btp_subaccount_service_instance` (`.labels[...]`) | Bug do provider 1.27.0: a última chave de label volta com uma aspa extra | Mantenha `label_service_manager_resources = false` (padrão); o próximo apply recria as instâncias marcadas como *tainted* |
| Role collection de uma aplicação "not found" | A role collection só existe depois que a assinatura termina, ou o nome mudou | Confira com `btp list security/role-collection --subaccount <id>` e ajuste `subscriptions` no stack 15 |
| Aplicação abre com tela de escolha de IdP | O IAS ainda não é o IdP padrão ou o `sap.default` continua disponível | Confira `btp list security/trust --subaccount <id>` e o output `ias_origin` do stack 15 |
| Não chegou o e-mail de ativação do IAS | O tenant já existia para o global account (vinculado, não criado) | Acesse `ias_admin_console` e use "Esqueci minha senha", ou peça o reenvio no IAS |
| Ansible: `Recursos sem labels de FinOps` | Recurso criado à mão no cockpit, sem labels | Crie pelo Terraform ou rotule com `cf set-label`; o CSV em `.build/finops/` mostra o que falta |
| Todo `plan` mostra mudança | Valor volátil (`timestamp()`) ou atributo alterado fora do Terraform | `make drift` mostra o que mudou; remova valores voláteis |
| Trial "suspended" | 30 dias sem extensão | Estenda no cockpit da trial |

## Comandos úteis de diagnóstico

```bash
btp --info                                         # usuário, global account e config em uso
btp list accounts/subaccount
btp list accounts/entitlement --subaccount <id>
btp get accounts/subaccount <id>                   # inclui as labels
terraform -chdir=terraform/stacks/10-btp-account output
make login-cf && cf org-users <org> && cf space-users <org> integration
cf curl "/v3/service_instances?label_selector=environment=qa" | jq '.resources[].name'
TF_LOG=DEBUG terraform -chdir=terraform/stacks/20-cloudfoundry plan   # log detalhado
```
