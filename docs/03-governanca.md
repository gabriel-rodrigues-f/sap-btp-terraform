# 3. Governança: nomes, labels de FinOps e permissões

Os três temas são definidos **uma única vez** e aplicados em todos os recursos.
Mudar uma regra é mudar um módulo, não caçar strings pelo código.

| Tema | Onde é definido | Onde é aplicado |
| --- | --- | --- |
| Nomes | `terraform/modules/naming` | Stack 10 e stack 20 (os dois chamam o mesmo módulo) |
| Labels de FinOps | `terraform/modules/finops-labels` | Todos os recursos do BTP e do Cloud Foundry; a org recebe pelo Ansible |
| Permissões | `access` no tfvars + `locals` dos stacks | Directory, subaccount, org e space |

---

## 1. Convenção de nomes (inspirada no Azure CAF)

Padrão: **`<workload>-<ambiente>-<região>[-<instância>]`**

| Nível BTP | Equivalente no Azure CAF | Padrão | Exemplo |
| --- | --- | --- | --- |
| Directory | Management group | `<unidade-de-negócio>` | `corporate-it` |
| Subaccount (nome) | Resource group | `<workload>-<ambiente>-<região>` | `application-integration-qa-us10` |
| Subaccount (subdomínio) | Nome globalmente único | `<nome>-<sufixo>` | `application-integration-qa-us10-203d9eeb` |
| Org Cloud Foundry | — | `<nome>-<sufixo>` | `application-integration-qa-us10-203d9eeb` |
| Space | — | `<finalidade>` | `integration` |
| Instância de serviço | Recurso com prefixo de tipo | `<abrev>-<workload>-<ambiente>-<região>-<nnn>` | `dest-application-integration-qa-us10-001` |
| Service key | — | `sk-<consumidor>` | `sk-cicd`, `sk-integration-suite` |

Decisões e motivos:

- **Ambiente com valores fechados** (`sbx`, `dev`, `qa`, `prd`): se cada um escreve
  `QA`, `hml` ou `homolog`, o relatório de custo quebra em grupos diferentes.
- **Região no nome**: o mesmo workload pode existir em `us10` e `eu10`; o nome já
  diz onde ele roda (e onde está o dado).
- **Sufixo estável, nunca aleatório**: subdomínio e nome de org são únicos *na
  região inteira*, entre todos os clientes SAP. O sufixo vem do global account
  (`203d9eebtrial-ga` → `203d9eeb`), então não muda a cada recriação.
- **Space sem ambiente**: o ambiente já está no nome da org; o space diz a
  *finalidade* (`integration`, `monitoring`...).
- **Abreviação por tipo de serviço** (`dest`, `uaa`, `conn`, `ff`, `ans`, `html5`,
  `log`, `audit`, `sm`...): igual aos prefixos `rg-`, `st-`, `kv-` do CAF. A
  tabela completa fica em `modules/naming/main.tf`.
- **Uma service key por consumidor**: revogar o acesso do pipeline (`sk-cicd`)
  não derruba a integração (`sk-integration-suite`).

---

## 2. Labels de FinOps

Taxonomia única (baseada nas recomendações de *cost allocation* da FinOps Foundation):

| Label | Exemplo | Para que serve | Obrigatória |
| --- | --- | --- | --- |
| `cost-center` | `cc-1001` | Quem paga (chargeback) | ✅ |
| `business-unit` | `corporate-it` | Showback por área | ✅ |
| `workload` | `application-integration` | Custo por produto/aplicação | ✅ |
| `environment` | `qa` | Separar produtivo de não produtivo | ✅ |
| `region` | `us10` | Custo e residência de dados por região | ✅ |
| `owner` | `platform-team` | Time responsável | ✅ |
| `criticality` | `medium` | Prioridade de otimização e suporte | ✅ |
| `data-classification` | `internal` | Governança e compliance | ✅ |
| `managed-by` | `terraform` | Detectar recurso criado à mão | ✅ |
| `iac-repository` | `sap-btp-terraform` | Onde está o código que criou o recurso | |
| `owner-contact` | `voce@exemplo.com` | Quem acionar (label no BTP, **annotation** no CF) | |
| `resource-type` | `subaccount`, `service-key`... | Filtrar o inventário por tipo | (automática) |
| `service` / `plan` | `destination` / `lite` | Custo por serviço e plano | (automática) |
| `consumer` | `cicd` | Quem usa cada service key | (automática) |

### Onde cada label é aplicada

| Recurso | Formato | Quem aplica |
| --- | --- | --- |
| Directory | `map(set(string))`, sem workload/ambiente (é da unidade inteira) | Terraform |
| Subaccount | `map(set(string))` | Terraform |
| Instância e service key no nível do subaccount | `map(set(string))` + `service`, `plan`, `consumer` | Terraform |
| Space, instância e service key no Cloud Foundry | `map(string)` + annotations | Terraform |
| **Org Cloud Foundry** | `map(string)` + annotations | **Ansible** (a org é criada pelo BTP; o provider CF não é dono dela) |
| Assinatura SaaS | — | A API do BTP **não aceita** labels em assinaturas; o custo é atribuído pelas labels do subaccount |

### Regras do Cloud Foundry que o módulo já valida

- Valor de label: até 63 caracteres, letras, números, `-`, `_` e `.`, começando e
  terminando com letra ou número. **E-mail e URL não cabem**, por isso vão em
  *annotations* (`owner-contact`, `iac-repository-url`).
- Map vazio em `labels` e lista vazia em `tags` são rejeitados pelo provider; os
  módulos convertem vazio em `null`.

### Auditoria

O Terraform garante as labels do que **ele** cria. O Ansible (`make configure`)
audita o Cloud Foundry **real**: org, spaces, instâncias e service keys, inclusive
o que alguém criou à mão no cockpit. Ele gera `.build/finops/cf-inventory.csv`
e falha se algum recurso estiver sem label obrigatória.

---

## 3. Permissões (RBAC por persona)

Ninguém recebe papel avulso: cada pessoa entra numa **persona**, e cada persona
recebe um conjunto coerente de papéis em todos os níveis.

| Persona | Directory | Subaccount | Org Cloud Foundry | Space |
| --- | --- | --- | --- | --- |
| `platform_admins` | Directory Administrator | Subaccount Administrator | `organization_manager` | `space_manager` + `space_developer` |
| `developers` | — | Subaccount Viewer + Destination Administrator | `organization_user` | `space_developer` |
| `auditors` | Directory Viewer | Subaccount Viewer | `organization_auditor` | `space_auditor` |
| `finops` | Directory Viewer | Subaccount Viewer | `organization_billing_manager` | — |

```hcl
# terraform/stacks/10-btp-account/terraform.tfvars
access = {
  platform_admins = ["voce@exemplo.com"]
  developers      = ["dev@exemplo.com"]
  auditors        = ["auditoria@exemplo.com"]
  finops          = ["finops@exemplo.com"]
}
```

Detalhes que o código trata:

- **Directory com AUTHORIZATIONS**: só assim o directory tem administradores e
  viewers próprios. O feature exige ENTITLEMENTS, então a cota passa a fluir
  `global account → directory → subaccount`, e o módulo cria os entitlements do
  directory antes dos do subaccount.
- **Todo mundo vira membro da org** (`organization_user`) antes de receber
  qualquer outro papel. O Cloud Foundry só aceita papel de space para quem já é
  membro da org.
- **O deployer** (quem roda o Terraform, lido via `data "btp_whoami"`) já vira
  Org Manager quando o BTP cria a org. Como a API do CF recusa papel repetido, ele
  fica fora do módulo `cf-org-access` e recebe só `space_developer`, que é o papel
  necessário para criar instâncias de serviço.
- **Usuários precisam existir no UAA** para receber papel no Cloud Foundry: a
  pessoa precisa ter feito login no CF daquela região ao menos uma vez. No BTP
  (role collections), não há essa exigência.
- **Grupos em vez de usuários**: em produção, troque e-mails por grupos do IdP
  corporativo (SAP Cloud Identity Services). `btp_*_role_collection_assignment`
  aceita `group_name`, e quem entra ou sai do grupo herda ou perde o acesso sem
  mudança no Terraform.
