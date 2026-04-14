.PHONY: help install test clean tf-fmt tf-init tf-validate tf-plan tf-apply tf-destroy

PYTHON := python
PIP := pip
TF_ENV := infra/terraform/envs/dev

help:
	@echo "Targets disponibles:"
	@echo "  install       Instala dependencias Python"
	@echo "  test          Ejecuta pruebas con pytest"
	@echo "  clean         Elimina caches locales de Python y pytest"
	@echo "  tf-fmt        Formatea archivos Terraform"
	@echo "  tf-init       Inicializa Terraform en env dev"
	@echo "  tf-validate   Valida Terraform en env dev"
	@echo "  tf-plan       Genera plan de Terraform en env dev"
	@echo "  tf-apply      Aplica Terraform en env dev"
	@echo "  tf-destroy    Destruye Terraform en env dev"

install:
	$(PIP) install -r requirements.txt

test:
	pytest -q

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

tf-fmt:
	terraform fmt -recursive infra/terraform

tf-init:
	terraform -chdir=$(TF_ENV) init

tf-validate:
	terraform -chdir=$(TF_ENV) validate

tf-plan:
	terraform -chdir=$(TF_ENV) plan

tf-apply:
	terraform -chdir=$(TF_ENV) apply -auto-approve

tf-destroy:
	terraform -chdir=$(TF_ENV) destroy -auto-approve