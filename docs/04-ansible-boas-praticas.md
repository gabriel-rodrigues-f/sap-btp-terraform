# 4. Boas práticas de Ansible aplicadas aqui

## Por que Ansible, se o Terraform já cria tudo?

O provider `cloudfoundry` até tem `cloudfoundry_app`, mas deploy de aplicação
tem outra natureza:

| Infraestrutura (Terraform) | Workload (Ansible) |
| --- | --- |
| Muda pouco; ciclo de vida longo | Muda a cada release |
| Estado declarativo, diff, drift | Passos ordenados: build, push, verificação |
| `destroy` faz sentido | "Desfazer" é fazer rollback para a versão anterior |

Misturar os dois no mesmo estado faz cada release passar por um `terraform
apply` da plataforma, e um erro de app pode bloquear mudanças de infra. Aqui,
cada ferramenta tem o seu papel e eles se falam por **outputs**.

## Inventário: localhost

No BTP não há VM para acessar por SSH; tudo é API. O "host" é a máquina de
controle (`inventory/hosts.yml`), que fala com o BTP via cf CLI e HTTP. Em CI,
é o próprio runner.

## O contrato com o Terraform

A role `btp_context` usa `cloud.terraform.terraform_output` para ler os
**outputs** do stack 20. Ela não lê o `tfstate` e não tem nomes de org ou space
fixos no código. Se o Terraform mudar o nome do space, o Ansible acompanha
sem alteração.

## Idempotência de verdade com `cf push`

`cf push` sempre reconstrói e reinicia a app, então não é idempotente. A role
`cf_app` resolve isso assim:

1. Calcula um *digest* de código, configuração (memória, rotas, serviços, env)
   e template do manifesto.
2. Grava o digest como *annotation* da app (`metadata.annotations.deploy-digest`
   no manifesto).
3. Na próxima execução, lê a annotation via `cf curl /v3/apps` e só faz push
   se o digest mudou.

Resultado: a segunda execução seguida termina com `changed=0`.
`-e cf_app_force_push=true` força o deploy (ex.: para pegar um buildpack novo).

## Deploy sem downtime

`cf push --strategy rolling`: novas instâncias sobem e passam no health check
HTTP (`/health`) antes das antigas pararem. `canary` também é aceito em
`cf_app_strategy`.

## Check mode útil

```bash
make deploy-check     # ansible-playbook site.yml --check --diff
```

Tasks de leitura (`cf api`, `cf curl`, cálculo de digest) usam
`check_mode: false` para rodar de verdade no dry-run. Assim o `--check` mostra
o diff real do manifesto e se haveria push.

## Roles pequenas e com contrato

| Role | Responsabilidade |
| --- | --- |
| `preflight` | CLIs instalados (falha cedo, com instrução) |
| `btp_context` | Outputs do Terraform → fato `btp_context_info` |
| `cf_target` | Autentica (`cf auth`), define o endpoint e faz target na org/space certos |
| `cf_app` | Deploy idempotente por digest |
| `smoke_test` | `/health` e leitura da destination criada pelo Terraform |

- `meta/argument_specs.yml` valida as entradas de cada role antes de executar.
- Variáveis prefixadas com o nome da role (`cf_app_*`) evitam colisões.
- Módulos com FQCN (`ansible.builtin.command`), `argv` em vez de string de shell
  (sem problemas de aspas ou injeção) e `changed_when` explícito em todo `command`.
- `no_log: true` na autenticação; a senha vai para o `cf auth` por variável de
  ambiente, nunca em `argv` (que aparece em `ps`). Ela vem de `BTP_PASSWORD`,
  lida em `group_vars` com `lookup('ansible.builtin.env', ...)`.

## Parâmetros por ambiente

`inventory/group_vars/btp_control.yml` guarda só o que muda entre ambientes
(nome da app, memória, instâncias, destination). Os defaults técnicos ficam em
`roles/*/defaults`. Org, space e serviços vêm do Terraform.

## Toolchain reproduzível

- `requirements.txt` fixa `ansible-core`, `ansible-lint` e `yamllint`, instalados numa `.venv`.
- `requirements.yml` fixa as coleções, instaladas **dentro** do repo (`ansible/collections/`, fora do git).
- `ansible.cfg` versionado: quem roda de dentro de `ansible/` tem o mesmo comportamento.
- `ansible-lint` no perfil `production`, o mais rigoroso.

## Teardown simétrico

`playbooks/teardown.yml` remove o que **o Ansible** criou (app e rota) antes
de `terraform destroy`. Cada ferramenta desfaz o que fez.

## E as coleções SAP para Ansible?

Existe a coleção `sap.sap_operations` (Red Hat), com módulos para BTP e Cloud
Foundry (`btp_subaccount`, `cf_service_instance` e outros). Ela é uma
alternativa para quem quer fazer tudo em Ansible. Aqui ficamos com o Terraform
na infraestrutura, por causa de estado, plan e drift, e com o cf CLI no
deploy, porque é a ferramenta oficial e funciona igual na máquina local e no CI.
