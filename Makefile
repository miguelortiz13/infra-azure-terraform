SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ENV ?= dev

.PHONY: help
help: ## Muestra este menú de ayuda
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: tools
tools: ## Instala tflint, gitleaks y pre-commit en ~/.local/bin
	@./scripts/install-tools.sh

.PHONY: doctor
doctor: ## Verifica que las herramientas necesarias estén instaladas
	@echo "Herramientas:"
	@command -v terraform >/dev/null 2>&1 && echo "  ✔ terraform → $$(which terraform) ($$(terraform version -json | jq -r .terraform_version))" || echo "  ✖ terraform no instalado"
	@command -v az >/dev/null 2>&1 && echo "  ✔ az CLI    → $$(which az) ($$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'ok'))" || echo "  ✖ az no instalado"
	@command -v tflint >/dev/null 2>&1 && echo "  ✔ tflint    → $$(which tflint) ($$(tflint --version | head -n1))" || echo "  ✖ tflint no instalado"
	@command -v gitleaks >/dev/null 2>&1 && echo "  ✔ gitleaks  → $$(which gitleaks) ($$(gitleaks version))" || echo "  ✖ gitleaks no instalado"
	@command -v pre-commit >/dev/null 2>&1 && echo "  ✔ pre-commit→ $$(which pre-commit) ($$(pre-commit --version))" || echo "  ✖ pre-commit no instalado"
	@echo "Azure Context:"
	@az account show --query "{Subscription:name, Id:id, State:state}" -o table 2>/dev/null || echo "  ✖ Inicia sesión con 'az login'"

.PHONY: fmt
fmt: ## Formatea todos los archivos Terraform recursivamente
	@terraform fmt -recursive

.PHONY: fmt-check
fmt-check: ## Verifica el formato sin modificar archivos
	@terraform fmt -recursive -check

.PHONY: tflint
tflint: ## Ejecuta tflint sobre los módulos y entornos
	@echo "Ejecutando tflint..."
	@tflint --recursive

.PHONY: lint
lint: ## Ejecuta pre-commit sobre todos los archivos
	@pre-commit run --all-files

.PHONY: init
init: ## Inicializa un entorno (ej: make init ENV=dev o ENV=bootstrap)
	@echo "Inicializando entorno: $(ENV)"
	@if [ "$(ENV)" = "bootstrap" ]; then \
		cd bootstrap && terraform init; \
	else \
		cd envs/$(ENV) && terraform init; \
	fi

.PHONY: validate
validate: ## Valida la sintaxis de Terraform en todos los módulos y entornos
	@echo "Validando bootstrap..."
	@cd bootstrap && terraform init -backend=false >/dev/null 2>&1 && terraform validate
	@for m in modules/*; do \
		if [ -d "$$m" ]; then \
			echo "Validando $$m..."; \
			(cd "$$m" && terraform init -backend=false >/dev/null 2>&1 && terraform validate); \
		fi; \
	done
	@for e in envs/*; do \
		if [ -d "$$e" ]; then \
			echo "Validando $$e..."; \
			(cd "$$e" && terraform init -backend=false >/dev/null 2>&1 && terraform validate); \
		fi; \
	done

.PHONY: plan
plan: ## Genera un plan de Terraform para el entorno (ej: make plan ENV=dev)
	@echo "Generando plan para $(ENV)..."
	@if [ "$(ENV)" = "bootstrap" ]; then \
		cd bootstrap && terraform plan; \
	else \
		cd envs/$(ENV) && terraform plan; \
	fi

.PHONY: apply
apply: ## Aplica la infraestructura para el entorno (ej: make apply ENV=dev)
	@echo "Aplicando cambios en $(ENV)..."
	@if [ "$(ENV)" = "bootstrap" ]; then \
		cd bootstrap && terraform apply; \
	else \
		cd envs/$(ENV) && terraform apply; \
	fi

.PHONY: destroy
destroy: ## Destruye la infraestructura del entorno (ej: make destroy ENV=dev)
	@echo "Destruyendo infraestructura en $(ENV)..."
	@if [ "$(ENV)" = "bootstrap" ]; then \
		cd bootstrap && terraform destroy; \
	else \
		cd envs/$(ENV) && terraform destroy; \
	fi
