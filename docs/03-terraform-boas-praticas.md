# 3. Boas práticas de Terraform aplicadas aqui

Cada seção aponta onde a prática aparece no código.

## Camadas com estados separados (stacks)

```text
stacks/10-btp-subaccount  ->  outputs  ->  stacks/20-cf-space  ->  outputs  ->  Ansible
```

- **Por quê dois stacks?** O provider `cloudfoundry` precisa do endpoint de uma
  org que só existe depois do apply do stack 10. Colocar os dois providers no
  mesmo root module faz o primeiro `plan` falhar ou depender de gambiarras.
- **Raio de impacto menor**: um erro no space não arrisca o subaccount.
- **Permissões separadas**: quem opera spaces não precisa poder destruir subaccounts.
- **Plans mais rápidos**: cada stack consulta só a sua API.

O contrato entre camadas são os **outputs** (`stacks/10-btp-subaccount/outputs.tf`).
O stack 20 lê esses outputs com `terraform_remote_state` (`stacks/20-cf-space/data.tf`),
nunca recursos internos do outro stack. Com backend remoto, aponte o
`terraform_remote_state` para o mesmo backend. Para acoplar ainda menos, o
pipeline pode passar os valores como variáveis (`TF_VAR_cf_org_id=...`).

## Módulos x root modules

| | Módulo (`terraform/modules/*`) | Root module (`terraform/stacks/*`) |
| --- | --- | --- |
| Versão de provider | Mínimo necessário (`>= 1.27.0`) | Faixa (`~> 1.27`) + `.terraform.lock.hcl` **versionado** |
| Bloco `provider` | Nunca | Sim |
| Backend | Nunca | Sim |
| Testes | `tests/*.tftest.hcl` com mocks | `make validate`; apply real na trial |

Módulos não são *wrappers* de um recurso só: cada um entrega uma capacidade
completa (o "subaccount pronto para uso", a "org com endpoint", o "space com
serviços").

O lock file foi gerado para várias plataformas, para que Mac, Linux e CI
validem o mesmo hash:

```bash
terraform -chdir=terraform/stacks/10-btp-subaccount providers lock \
  -platform=darwin_arm64 -platform=darwin_amd64 -platform=linux_amd64 \
  -platform=linux_arm64 -platform=windows_amd64
```

## `for_each` com chaves estáveis

```hcl
# modules/btp-subaccount/main.tf
entitlements = { for e in var.entitlements : "${e.service_name}/${e.plan_name}" => e }
```

A chave vem de atributos de negócio, não da posição na lista. Reordenar a
lista não recria nada. Com `count`, remover o primeiro item "deslocaria" todos
os outros, e o Terraform destruiria e recriaria entitlements à toa.

## Variáveis tipadas e validadas

- `type = list(object({ ... optional(...) }))` em vez de `any`: o erro aparece
  no `plan`, com mensagem clara, e não no meio do `apply`.
- Blocos `validation` impedem subdomínio inválido, entitlement duplicado,
  e-mail malformado e JSON quebrado em `parameters`.
- `parameters` é uma **string JSON**, não `any`. Mapas com valores `any` de
  formatos diferentes não convertem; uma string sempre converte. Em HCL use
  `jsonencode()`/`file()`; em `.tfvars`, heredoc (tfvars não aceita funções).

## Dependências explícitas e mínimas

- Dentro do módulo: `depends_on = [btp_subaccount_entitlement.this]` na
  assinatura e na destination, porque a API exige o entitlement e não existe
  referência de atributo que o Terraform consiga inferir.
- Entre módulos: **sem** `depends_on` no nível do módulo. O output `id` do
  módulo `btp-subaccount` declara `depends_on` nos entitlements. Quem consome
  `module.subaccount.id` herda a dependência sem adiar todos os data sources
  para o apply (efeito colateral do `depends_on` em módulo).

## Nada de valores voláteis

`timestamp()`, `uuid()` ou datas em labels geram um diff novo a cada `plan`. A
saída fica poluída e mudanças reais passam despercebidas. As labels aqui são
estáveis: `managed-by`, `project`, `stage`.

## Nomes únicos por construção

Subdomínio de subaccount e nome de org precisam ser únicos **na região
inteira**, entre todos os clientes SAP. O stack 10 usa o prefixo do subdomínio
do seu global account (`1a2b3c4dtrial-ga` → `1a2b3c4dtrial-btp-poc-dev`), que
já é único. Nada de sufixo aleatório, que mudaria a cada recriação.

## Plan revisado = apply executado

```bash
make account-plan     # terraform plan -out=tfplan
make account-apply    # terraform apply tfplan
```

O `apply` executa exatamente o plano que você leu. Se algo mudou no BTP entre
um e outro, o Terraform recusa o plano desatualizado.

## Drift

```bash
make drift    # terraform plan -refresh-only -detailed-exitcode
```

Detecta alterações feitas no cockpit. O exit code 2 indica drift, o que dá
para agendar no CI. A regra é corrigir no código e aplicar, nunca o contrário.

## Testes sem credenciais

`terraform test` com `mock_provider` (Terraform 1.7+) roda offline:

```hcl
mock_provider "btp" {}

run "falha_se_broker_nao_devolver_endpoint" {
  command   = apply
  state_key = "sem_endpoint"            # estado isolado deste run
  override_resource {
    target = btp_subaccount_environment_instance.this
    values = { labels = "{}" }          # simula a resposta do broker
  }
  expect_failures = [output.api_endpoint]
}
```

Três lições que os testes deste repositório já ensinaram:

- Atributos *computed* (ex.: `amount` sem valor) ficam desconhecidos no
  `plan`. Asserte sobre eles só com `command = apply`.
- O provider CF rejeita `labels = {}` e `tags = []`. Os módulos convertem
  vazio em `null`, e há teste para isso.
- Runs compartilham estado. Se a config não muda, o recurso não é recriado e o
  `override_resource` não tem efeito. Use `state_key` para isolar.

## Importar recursos existentes

Para trazer algo criado fora do Terraform (ex.: o subaccount `trial`), use um
bloco `import` e deixe o Terraform gerar o HCL:

```hcl
import {
  to = btp_subaccount.trial
  id = "<ID_DO_SUBACCOUNT>"
}
```

```bash
terraform plan -generate-config-out=generated.tf
```

Depois de importado, o recurso é gerenciado: um `destroy` o apaga. Para
recursos que você não quer arriscar, adicione `lifecycle { prevent_destroy = true }`.

## Refatorar sem destruir: `moved`

Ao renomear um recurso ou movê-lo para um módulo, declare a mudança e o
Terraform só atualiza o endereço no estado:

```hcl
moved {
  from = btp_subaccount.app_dev_rpa
  to   = module.subaccount.btp_subaccount.this
}
```

## Estado

- Local na POC (`backend "local"`), fora do git.
- Em time ou produção: backend remoto com criptografia e lock. Há exemplos
  comentados em `stacks/10-btp-subaccount/backend.tf`. Use um estado por stack e
  por estágio (`btp/<projeto>/<stage>/<stack>.tfstate`).
