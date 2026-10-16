# 3. Governança: nomes, labels de FinOps, identidade e permissões

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
| Space | — | `<value stream>` ou `shared-services` | `o2c`, `p2p`, `r2r`, `h2r`, `d2o` |
| Instância de serviço | Recurso com prefixo de tipo | `<abrev>[-<value stream>]-<workload>-<ambiente>-<região>-<nnn>` | `uaa-o2c-application-integration-qa-us10-001` |
| Service key | — | `sk-<consumidor>` | `sk-cicd`, `sk-integration-suite` |

Decisões e motivos:

- **Ambiente com valores fechados** (`sbx`, `dev`, `qa`, `prd`): se cada um escreve
  `QA`, `hml` ou `homolog`, o relatório de custo quebra em grupos diferentes.
- **Região no nome**: o mesmo workload pode existir em `us10` e `eu10`; o nome já
  diz onde ele roda (e onde está o dado).
- **Sufixo estável, nunca aleatório**: subdomínio e nome de org são únicos *na
  região inteira*, entre todos os clientes SAP. O sufixo vem do global account
  (`203d9eebtrial-ga` → `203d9eeb`), então não muda a cada recriação.
- **Space por value stream da SAP** (order-to-cash, procure-to-pay,
  record-to-report, hire-to-retire, design-to-operate): o ambiente já está no
  nome da org, e o space diz a qual processo de negócio o recurso serve.
- **Value stream no nome da instância**: garante unicidade entre spaces, o que é
  obrigatório para o `xsappname` do XSUAA (único por subaccount).
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
| `region` | `us10` | Custo e residência de dados por região (no BTP é atributo nativo do subaccount) | ✅ (CF) |
| `owner` | `platform-team` | Time responsável | ✅ |
| `criticality` | `medium` | Prioridade de otimização e suporte | ✅ |
| `data-classification` | `internal` | Governança e compliance | ✅ |
| `managed-by` | `terraform` | Detectar recurso criado à mão | ✅ |
| `iac-repository` | `sap-btp-terraform` | Onde está o código que criou o recurso (só CF) | |
| `owner-contact` | `voce@exemplo.com` | Quem acionar (label no BTP, **annotation** no CF) | |
| `resource-type` | `cf-space`, `service-key`... | Filtrar o inventário por tipo (só CF) | (automática) |
| `service` / `plan` | `destination` / `lite` | Custo por serviço e plano (só CF; no BTP são atributos nativos) | (automática) |
| `consumer` | `cicd` | Quem usa cada service key (BTP e CF) | (automática) |
| `value-stream` | `o2c`, `shared` | Custo por processo de negócio (spaces, instâncias e keys do CF) | (automática) |

### Onde cada label é aplicada

| Recurso | Formato | Quem aplica |
| --- | --- | --- |
| Directory | `map(set(string))`, 5 chaves (sem workload/ambiente: é da unidade inteira) | Terraform |
| Subaccount | `map(set(string))`, 9 chaves | Terraform |
| Instância no nível do subaccount | — por padrão (bug do provider, veja abaixo); o custo é atribuído pelas labels do subaccount | Terraform |
| Service key no nível do subaccount | — por padrão (mesmo bug) | Terraform |
| Space, instância e service key no Cloud Foundry | `map(string)` + annotations | Terraform |
| **Org Cloud Foundry** | `map(string)` + annotations | **Ansible** (a org é criada pelo BTP; o provider CF não é dono dela) |
| Assinatura SaaS | — | A API do BTP **não aceita** labels em assinaturas; o custo é atribuído pelas labels do subaccount |

### Limite do BTP: no máximo 10 chaves por recurso

A API do BTP recusa mais de 10 chaves de label num mesmo recurso. O limite não
aparece na documentação do provider; foi descoberto no primeiro `plan` desta
POC. Por isso o lado BTP leva só o essencial:

- ficam fora as labels que já são **atributos nativos** do objeto (`region` no
  subaccount, serviço e plano na instância) ou que só servem ao CF
  (`iac-repository`, `resource-type`);
- labels extras da empresa (`finops.extra`) vão só para o Cloud Foundry;
- o conjunto base tem 9 chaves, o que deixa 1 livre para a chave do recurso
  (`consumer` nas service keys).

Os módulos validam o limite (`length(var.labels) <= 10`), então o erro aparece
no `plan`, com mensagem clara, e há teste para isso.

### Bug do provider nas instâncias do Service Manager

No primeiro `apply` real (provider `SAP/btp` 1.27.0), as instâncias criadas
via Service Manager voltaram com a **última** chave de label corrompida:
`workload = application-integration"` (aspa extra no fim). O apply falha com
*Provider produced inconsistent result after apply*. Directory e subaccount usam
outro caminho na API e ficaram corretos (conferido via `btp get accounts/subaccount`).

Por isso o módulo `btp-services` tem `label_service_manager_resources = false`
por padrão: instâncias e service keys do Service Manager saem sem labels, e o
custo delas é atribuído pelas labels do subaccount, como nas assinaturas.
Quando o provider corrigir, basta ligar a opção. Esse é um bom exemplo de por que
vale rodar o `apply` real cedo: nenhum teste com mock pegaria esse bug.

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

## 3. Identidade: duas portas de entrada

| Porta | Quem usa | Identity provider | Onde é configurada |
| --- | --- | --- | --- |
| **Plataforma** | Cockpit, btp CLI, cf CLI, Terraform | SAP ID service (padrão do global account) | Global account |
| **Aplicações** | Integration Suite, BAS, Work Zone e demais assinaturas | **SAP Cloud Identity Services (IAS)** | Stack 15 |

O stack 15 monta a porta das aplicações de ponta a ponta:

1. **Onboarding do IAS** (`sap-identity-services-onboarding`): cria ou vincula
   o tenant e envia o **e-mail de ativação** para quem assinou.
2. **Trust OIDC** do subaccount com o tenant (`btp_subaccount_trust_configuration`).
3. **IAS como IdP padrão** (`btp_subaccount_security_settings.default_identity_provider`):
   quem abre uma aplicação vai direto para o login do IAS.
4. **SAP ID service fora do login das aplicações**: o trust `sap.default` é
   **importado** (bloco `import`) e recebe `available_for_user_logon = false`.
   O provider trata o `sap.default` de forma especial: sem `identity_provider` e
   sem apagar no `destroy`.
5. **Role collections das aplicações no usuário do IAS** (`origin` = origin do
   trust), atribuídas assim que cada assinatura existe. Cada atribuição
   referencia a SUA assinatura, então a role do BAS não espera o Integration Suite.

A porta da plataforma continua no SAP ID service de propósito: o Terraform
autentica com usuário e senha desse IdP. Levar a plataforma para o IAS é uma
configuração do **global account** (trust para usuários de plataforma) e
exigiria trocar a autenticação do Terraform (veja [docs/02](02-autenticacao.md)).

| Aplicação | Role collections atribuídas ao usuário do IAS |
| --- | --- |
| Integration Suite | `Integration_Provisioner` (depois da ativação: `PI_*`, `APIPortal.*`, `AuthGroup.*`) |
| Business Application Studio | `Business_Application_Studio_Administrator`, `_Developer`, `_Extension_Deployer` |
| Work Zone, standard edition | `Launchpad_Admin` |
| Build Code | `Build Code Administrator`, `Build Code Developer` |
| HANA Cloud Tools | `SAP HANA Cloud Administrator` |
| Automation Pilot | `AutomationPilot_Admin`, `AutomationPilot_Developer` |
| Demais (Build Apps, Process Automation, CI/CD, Cloud TMS, Audit Log Viewer, Feature Flags) | Descobertas depois da assinatura com `btp list security/role-collection` e incluídas em `subscriptions` |

## 4. Permissões (RBAC por persona)

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
