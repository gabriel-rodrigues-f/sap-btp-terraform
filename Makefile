# Atalhos da POC. Rode `make` (ou `make help`) para ver todos os alvos.
#
# Fluxo completo (credenciais em BTP_USERNAME / BTP_PASSWORD, veja docs/02):
#   make setup
#   make account-plan account-apply   # stack 10: directory, subaccount, serviços, org CF
#   make cf-plan cf-apply             # stack 20: papéis de org, spaces, instâncias, keys
#   make configure                    # Ansible: labels na org + auditoria de FinOps
#   make down                         # desfaz tudo, na ordem inversa

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory

TF             ?= terraform
TFLINT_VERSION := 0.64.0
VENV           := .venv
BIN            := $(CURDIR)/$(VENV)/bin
ACCOUNT_STACK  := terraform/stacks/10-btp-account
CF_STACK       := terraform/stacks/20-cloudfoundry
MODULES        := $(wildcard terraform/modules/*)
ANSIBLE        := cd ansible && PATH="$(BIN):$$PATH" ansible-playbook

# Lê o subdomínio do global account do tfvars (evita digitar duas vezes).
GLOBALACCOUNT  ?= $(shell sed -nE 's/^globalaccount *= *"([^"]+)".*/\1/p' $(ACCOUNT_STACK)/terraform.tfvars 2>/dev/null)

# Um único par de credenciais (BTP_USERNAME / BTP_PASSWORD) serve para tudo.
# O provider CF lê CF_USER/CF_PASSWORD e o cf CLI lê CF_USERNAME/CF_PASSWORD;
# o mapeamento é feito pelo SHELL (não pelo make), para que senhas com "$" não
# sejam reinterpretadas.
CF_ENV := CF_USER="$${CF_USER:-$$BTP_USERNAME}" CF_USERNAME="$${CF_USERNAME:-$$BTP_USERNAME}" CF_PASSWORD="$${CF_PASSWORD:-$$BTP_PASSWORD}"
# Não consultar a HashiCorp a cada comando (checagem de versão nova).
export CHECKPOINT_DISABLE := 1

##@ Preparação

.PHONY: help
help: ## Lista os alvos disponíveis
	@awk 'BEGIN {FS = ":.*##"; printf "\nUso: make <alvo>\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Cria .venv (Ansible, linters, tflint) e instala as coleções Ansible
	@command -v uv >/dev/null || { echo "Instale o uv: brew install uv"; exit 1; }
	uv venv --allow-existing --python 3.13 $(VENV)
	uv pip install --python $(BIN)/python -r requirements.txt
	scripts/install-tflint.sh $(TFLINT_VERSION) $(BIN)
	cd ansible && $(BIN)/ansible-galaxy collection install -r requirements.yml -p collections
	@for f in $(ACCOUNT_STACK) $(CF_STACK); do \
	  [ -f $$f/terraform.tfvars ] || { cp $$f/terraform.tfvars.example $$f/terraform.tfvars; echo "Criado $$f/terraform.tfvars: edite antes do plan"; }; \
	done

.PHONY: check-creds
check-creds: ## Confere se BTP_USERNAME e BTP_PASSWORD estão exportadas
	@[ -n "$${BTP_USERNAME:-}" ] && [ -n "$${BTP_PASSWORD:-}" ] || { \
	  echo "Exporte as credenciais antes:"; \
	  echo '  export BTP_USERNAME="voce@exemplo.com"'; \
	  echo '  read -rs BTP_PASSWORD && export BTP_PASSWORD'; \
	  exit 1; }

.PHONY: login-btp
login-btp: ## Login do btp CLI (pede usuário e senha) para os comandos manuais/discover
	@[ -n "$(GLOBALACCOUNT)" ] || { echo "Defina globalaccount em $(ACCOUNT_STACK)/terraform.tfvars"; exit 1; }
	btp login --url https://cli.btp.cloud.sap --subdomain $(GLOBALACCOUNT)

.PHONY: login-cf
login-cf: check-creds ## Autentica o cf CLI na org criada pelo stack 10 (para comandos manuais)
	cf api "$$($(TF) -chdir=$(ACCOUNT_STACK) output -raw cf_api_url)"
	$(CF_ENV) cf auth
	cf target -o "$$($(TF) -chdir=$(ACCOUNT_STACK) output -raw cf_org_name)"

.PHONY: discover
discover: ## (somente leitura, exige make login-btp) Subaccounts e entitlements do global account
	btp list accounts/subaccount
	btp list accounts/entitlement

##@ Terraform - stack 10 (conta BTP)

.PHONY: account-init
account-init: ## terraform init do stack 10
	$(TF) -chdir=$(ACCOUNT_STACK) init -input=false

.PHONY: account-plan
account-plan: check-creds account-init ## Gera o plano do stack 10 em tfplan (revise antes de aplicar!)
	$(TF) -chdir=$(ACCOUNT_STACK) plan -input=false -out=tfplan

.PHONY: account-apply
account-apply: check-creds ## Aplica EXATAMENTE o tfplan revisado do stack 10
	@[ -f $(ACCOUNT_STACK)/tfplan ] || { echo "Sem plano. Rode: make account-plan"; exit 1; }
	$(TF) -chdir=$(ACCOUNT_STACK) apply -input=false tfplan
	@rm -f $(ACCOUNT_STACK)/tfplan
	@echo; echo "Próximo passo: make cf-plan"

##@ Terraform - stack 20 (Cloud Foundry: papéis, spaces, serviços)

.PHONY: cf-init
cf-init: ## terraform init do stack 20
	$(TF) -chdir=$(CF_STACK) init -input=false

.PHONY: cf-plan
cf-plan: check-creds cf-init ## Gera o plano do stack 20 em tfplan
	$(CF_ENV) $(TF) -chdir=$(CF_STACK) plan -input=false -out=tfplan

.PHONY: cf-apply
cf-apply: check-creds ## Aplica EXATAMENTE o tfplan revisado do stack 20
	@[ -f $(CF_STACK)/tfplan ] || { echo "Sem plano. Rode: make cf-plan"; exit 1; }
	$(CF_ENV) $(TF) -chdir=$(CF_STACK) apply -input=false tfplan
	@rm -f $(CF_STACK)/tfplan
	@echo; echo "Próximo passo: make configure"

.PHONY: drift
drift: check-creds ## Detecta drift (mudanças feitas fora do Terraform) nos dois stacks
	$(TF) -chdir=$(ACCOUNT_STACK) plan -refresh-only -input=false -detailed-exitcode
	$(CF_ENV) $(TF) -chdir=$(CF_STACK) plan -refresh-only -input=false -detailed-exitcode

##@ Ansible (configuração e governança)

.PHONY: configure-check
configure-check: check-creds ## Dry-run: mostra o que o Ansible mudaria (--check --diff)
	$(ANSIBLE) playbooks/site.yml --check --diff

.PHONY: configure
configure: check-creds ## Labels na org + auditoria de FinOps (relatório em .build/finops/)
	$(ANSIBLE) playbooks/site.yml

##@ Desmontagem

.PHONY: down
down: check-creds ## Destrói stack 20 e depois stack 10 (pede confirmação em cada um)
	$(CF_ENV) $(TF) -chdir=$(CF_STACK) destroy -input=false
	$(TF) -chdir=$(ACCOUNT_STACK) destroy -input=false

##@ Qualidade (não precisam de credenciais)

.PHONY: fmt
fmt: ## Formata o código Terraform
	$(TF) fmt -recursive terraform

.PHONY: validate
validate: ## terraform validate em módulos e stacks (sem backend)
	@for d in $(MODULES) $(ACCOUNT_STACK) $(CF_STACK); do \
	  echo "==> $$d"; \
	  $(TF) -chdir=$$d init -backend=false -input=false >/dev/null; \
	  $(TF) -chdir=$$d validate; \
	done

.PHONY: test
test: ## Testes unitários dos módulos com providers mockados (terraform test)
	@for d in $(MODULES); do \
	  echo "==> $$d"; \
	  $(TF) -chdir=$$d init -backend=false -input=false >/dev/null; \
	  $(TF) -chdir=$$d test; \
	done

.PHONY: lint
lint: ## fmt -check, tflint, ansible-lint e yamllint
	$(TF) fmt -check -recursive terraform
	$(BIN)/tflint --chdir=terraform --recursive --config "$(CURDIR)/terraform/.tflint.hcl"
	cd ansible && PATH="$(BIN):$$PATH" ansible-lint
	$(BIN)/yamllint -s .

.PHONY: check
check: lint validate test ## Tudo o que o CI roda

.PHONY: clean
clean: ## Remove caches locais (.terraform, .build). NÃO apaga tfstate.
	find terraform -type d -name .terraform -prune -exec rm -rf {} +
	rm -rf .build
