# Instruções para o Claude Code neste repositório

## Regra de identidade (obrigatória)

Este repositório opera **somente** a conta trial SAP BTP de
`gabrielvinicius.rodrigues@outlook.com` (global account `203d9eebtrial-ga`).
Neste computador também existem credenciais de outra conta
(`gabriel.freire@lab2dev.com`, exportadas no `~/.zshrc`), que **nunca** podem
ser usadas aqui.

Antes de QUALQUER autenticação ou comando que use credenciais (`btp`, `cf`,
`terraform plan/apply/destroy`, `ansible-playbook`, `make` com alvos de
plan/apply/configure/login):

1. Verifique a identidade ativa:
   - `btp --info` → linha `User:` deve ser `gabrielvinicius.rodrigues@outlook.com`
     e o target deve ser `203d9eebtrial-ga`;
   - `cf target` → `user:` deve ser `gabrielvinicius.rodrigues@outlook.com`;
   - no terminal onde o Terraform roda, `BTP_USERNAME` deve ser
     `gabrielvinicius.rodrigues@outlook.com` (o `make check-creds` confere).
2. Se for qualquer outra identidade, **pare** e peça ao usuário para corrigir.
   Nunca rode nada "para ver se funciona" com outra conta.

As travas no código reforçam a regra, mas não a substituem:
- `make check-creds` bloqueia se `BTP_USERNAME` for diferente do primeiro
  `access.platform_admins` do `terraform/stacks/10-btp-account/terraform.tfvars`;
- stacks 10 e 15: pós-condição no `data "btp_whoami"` barra o `plan`;
- Ansible (role `cf_target`): recusa credenciais diferentes do deployer.

## Outras convenções

- Senhas nunca vão para arquivo, argumento de linha de comando ou saída do
  terminal; o usuário as digita (`read -rs`) no próprio terminal.
- Toda mudança na conta passa por `plan` revisado antes do `apply`.
- `make check` (sem credenciais) precisa passar antes de cada commit.
