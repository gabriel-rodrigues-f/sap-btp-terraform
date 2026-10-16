# 5. Boas práticas de Ansible aplicadas aqui

## Por que Ansible, se o Terraform já cria tudo?

O Terraform é dono do ciclo de vida dos recursos. O Ansible entra em duas
situações em que o modelo declarativo do Terraform não se encaixa bem:

| Situação | Por que não é Terraform | Role |
| --- | --- | --- |
| **Rotular a org Cloud Foundry** | A org é criada pelo BTP (instância de ambiente). Gerenciá-la com o provider CF exigiria importá-la e disputar a posse com o provider BTP | `cf_org_metadata` |
| **Auditar o ambiente real** | O Terraform só enxerga o que está no estado dele. Recursos criados à mão no cockpit ficam invisíveis | `finops_compliance` |

A regra usada no repositório: **o que tem ciclo de vida de infraestrutura e
provider declarativo vai para o Terraform; o que é procedural, completa lacunas
ou verifica o mundo real vai para o Ansible.** As duas ferramentas se falam por
outputs.

## Inventário: localhost

No BTP não há VM para acessar por SSH; tudo é API. O "host" é a máquina de
controle (`inventory/hosts.yml`), que fala com o BTP via cf CLI. Em CI, é o
próprio runner.

## O contrato com o Terraform

A role `btp_context` usa `cloud.terraform.terraform_output` para ler os
**outputs** do stack 20: org, spaces, labels desejadas para a org e a lista de
labels obrigatórias. Ela não lê o `tfstate` e não tem nenhum nome fixo no código.
Se a política de labels mudar no módulo `finops-labels`, a auditoria acompanha.

## Roles pequenas e com contrato

| Role | Responsabilidade |
| --- | --- |
| `preflight` | CLIs instalados (falha cedo, com instrução) |
| `btp_context` | Outputs do Terraform → fato `btp_context_info` |
| `cf_target` | Autentica (`cf auth`), define o endpoint e faz target na org |
| `cf_org_metadata` | Aplica labels e annotations de FinOps na org, só quando algo difere |
| `finops_compliance` | Lê org, spaces, instâncias e service keys pela API v3, confere as labels obrigatórias, gera `.build/finops/cf-inventory.csv` e falha se houver recurso fora do padrão |

- `meta/argument_specs.yml` valida as entradas de cada role antes de executar.
- Variáveis prefixadas com o nome da role (`finops_compliance_*`) evitam colisões.
- Lógica de dados em Python (`roles/finops_compliance/filter_plugins/finops.py`),
  não em Jinja aninhado: fica legível e testável.
- Módulos com FQCN (`ansible.builtin.command`), `argv` em vez de string de shell
  (sem problemas de aspas ou injeção) e `changed_when` explícito em todo `command`.

## Idempotência

- `cf_org_metadata` faz `GET` da org, compara labels e annotations atuais com as
  desejadas e só faz `PATCH` quando há diferença. A segunda execução seguida
  termina com `changed=0`.
- `finops_compliance` só lê. O único arquivo que escreve (o CSV) é gerado por
  `template`, que reporta mudança apenas quando o conteúdo muda.

## Check mode útil

```bash
make configure-check     # ansible-playbook site.yml --check --diff
```

Tasks de leitura (`cf api`, `cf curl` GET, `cf auth`) usam `check_mode: false`
para rodar de verdade no dry-run. Assim o `--check` mostra se haveria `PATCH` na
org e o resultado real da auditoria.

## Segredos

- A senha vem de `BTP_PASSWORD` (lida em `group_vars` com
  `lookup('ansible.builtin.env', ...)`) e vai para o `cf auth` por variável de
  ambiente, nunca em `argv` (que aparece em `ps`).
- `no_log: true` na autenticação, e `no_log` no `argument_specs` da senha.
- A auditoria lista service keys pelo nome, nunca pelas credenciais.

## Toolchain reproduzível

- `requirements.txt` fixa `ansible-core`, `ansible-lint` e `yamllint`, instalados numa `.venv`.
- `requirements.yml` fixa as coleções, instaladas **dentro** do repo (`ansible/collections/`, fora do git).
- `ansible.cfg` versionado: quem roda de dentro de `ansible/` tem o mesmo comportamento.
- `ansible-lint` no perfil `production`, o mais rigoroso.

## E as coleções SAP para Ansible?

Existe a coleção `sap.sap_operations` (Red Hat), com módulos para BTP e Cloud
Foundry (`btp_subaccount`, `cf_service_instance` e outros). Ela é uma
alternativa para quem quer fazer tudo em Ansible. Aqui ficamos com o Terraform
na infraestrutura, por causa de estado, plan e drift, e com o cf CLI no Ansible,
porque é a ferramenta oficial e funciona igual na máquina local e no CI.
