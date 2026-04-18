#!/usr/bin/env bash
set -euo pipefail

BRANCH_NAME="${BRANCH_NAME:-feature/mwaa-glue-spark-evolution}"
AUTO_COMMIT="${AUTO_COMMIT:-false}"
DATE_NOW="$(date +%Y-%m-%d_%H-%M-%S)"

echo "==> Validando que estás dentro de un repositorio Git..."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: este script debe correrse desde dentro de un repositorio Git."
  exit 1
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "==> Repo root: $REPO_ROOT"
echo "==> Creando o cambiando a la rama: $BRANCH_NAME"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

echo "==> Creando estructura base para la evolución del proyecto..."
mkdir -p dags
mkdir -p glue_jobs/utils
mkdir -p sql/validations
mkdir -p sql/business_queries
mkdir -p sql/legacy_athena_ctas
mkdir -p docs
mkdir -p scripts

echo "==> Copiando SQL actuales como referencia legacy..."
if [ -d "sql/athena" ]; then
  cp -n sql/athena/*.sql sql/legacy_athena_ctas/ 2>/dev/null || true
fi

echo "==> Generando inventario simple del estado actual..."
{
  echo "# Inventario del estado actual"
  echo
  echo "Fecha: $DATE_NOW"
  echo
  echo "## Rama actual"
  git branch --show-current
  echo
  echo "## Estructura principal"
  find . -maxdepth 2 -type d | sort
  echo
  echo "## Archivos SQL actuales"
  find sql -maxdepth 2 -type f | sort
} > docs/phase1_inventory.md

echo "==> Generando documento de decisión: qué se queda y qué cambia..."
{
  echo "# Fase 1 - Definir qué se queda y qué cambia"
  echo
  echo "## Objetivo"
  echo
  echo "Evolucionar el proyecto desde una solución funcional basada en Athena hacia una arquitectura más completa con:"
  echo
  echo "- Amazon MWAA (Airflow) para orquestación"
  echo "- AWS Glue Jobs con Spark para transformaciones"
  echo "- Parquet en la capa curated"
  echo "- Athena como capa de validación y demo"
  echo "- Logs visibles en MWAA, Glue y CloudWatch"
  echo "- Casos exitosos y fallidos controlados"
  echo
  echo "---"
  echo
  echo "## Qué se queda"
  echo
  echo "Estas piezas ya son valiosas y no deben borrarse:"
  echo
  echo "### Infraestructura y datos"
  echo "- Buckets S3 actuales: raw, curated y athena-results"
  echo "- Bases de datos: \`logidata_raw\` y \`logidata_curated\`"
  echo "- Glue Catalog actual"
  echo "- Estructura raw actual en S3"
  echo "- Queries de validación y de negocio en Athena"
  echo "- La lógica de negocio ya validada en SQL"
  echo
  echo "### Rol de Athena a partir de ahora"
  echo "Athena ya no será el motor principal de transformación, pero sí se mantiene para:"
  echo
  echo "- validación técnica"
  echo "- consultas de verificación"
  echo "- queries de negocio"
  echo "- demo final"
  echo "- consumo analítico"
  echo
  echo "---"
  echo
  echo "## Qué cambia"
  echo
  echo "### Orquestación"
  echo "Antes:"
  echo "- ejecución semi-manual con scripts"
  echo
  echo "Ahora:"
  echo "- MWAA / Airflow orquesta el pipeline"
  echo
  echo "### Transformaciones"
  echo "Antes:"
  echo "- CTAS en Athena"
  echo
  echo "Ahora:"
  echo "- Glue Jobs con Spark generan curated"
  echo
  echo "### Capa curated"
  echo "Antes:"
  echo "- creada por Athena"
  echo
  echo "Ahora:"
  echo "- escrita por Spark en Parquet sobre S3"
  echo
  echo "### Observabilidad"
  echo "Antes:"
  echo "- logs básicos en consola y Athena"
  echo
  echo "Ahora:"
  echo "- logs visibles en MWAA, Glue Jobs y CloudWatch"
  echo
  echo "---"
  echo
  echo "## Arquitectura objetivo"
  echo
  echo '\`\`\`text'
  echo "S3 raw"
  echo "  ↓"
  echo "MWAA (Airflow)"
  echo "  ↓"
  echo "Glue Jobs con Spark"
  echo "  ↓"
  echo "S3 curated en Parquet"
  echo "  ↓"
  echo "Glue Catalog"
  echo "  ↓"
  echo "Athena"
  echo "  ↓"
  echo "Queries de validación y demo"
  echo '\`\`\`'
  echo
  echo "---"
  echo
  echo "## Mapeo de transición"
  echo
  echo "| Componente actual | Estado | Evolución esperada |"
  echo "|---|---|---|"
  echo "| Raw en S3 | Se queda | Se mantiene igual |"
  echo "| Glue Catalog raw | Se queda | Se mantiene y se amplía a curated |"
  echo "| Athena CTAS | Referencia legacy | Se reemplaza gradualmente por Glue Spark |"
  echo "| Athena queries de negocio | Se queda | Se mantiene para demo y validación |"
  echo "| Scripts manuales | Se quedan como apoyo | Se reemplazan parcialmente por Airflow |"
  echo "| Capa curated actual | Referencia válida | Nueva versión será generada por Spark |"
  echo "| Logs básicos | Se quedan como evidencia | Se mejoran con MWAA + Glue + CloudWatch |"
  echo
  echo "---"
  echo
  echo "## Nueva estructura recomendada del repo"
  echo
  echo '\`\`\`text'
  echo "dags/"
  echo "glue_jobs/"
  echo "glue_jobs/utils/"
  echo "sql/validations/"
  echo "sql/business_queries/"
  echo "sql/legacy_athena_ctas/"
  echo "docs/"
  echo "scripts/"
  echo '\`\`\`'
  echo
  echo "---"
  echo
  echo "## Qué usar como referencia funcional"
  echo
  echo "La lógica actual en Athena debe usarse como contrato de negocio para reimplementar en Spark, especialmente:"
  echo
  echo "- \`02_ctas_pedidos_curated.sql\`"
  echo "- \`03_ctas_sensores_curated.sql\`"
  echo "- \`04_ctas_dimensiones.sql\`"
  echo
  echo "Y Athena debe conservar:"
  echo
  echo "- queries de validación"
  echo "- queries de negocio"
  echo "- vista de demo final"
  echo
  echo "---"
  echo
  echo "## Siguiente paso recomendado"
  echo
  echo "1. crear \`glue_jobs/pedidos_curated_job.py\`"
  echo "2. mover la lógica de \`02_ctas_pedidos_curated.sql\` a Spark"
  echo "3. escribir salida en Parquet en curated"
  echo "4. validar el resultado con Athena"
} > docs/phase1_keep_vs_change.md

echo "==> Generando checklist corto..."
{
  echo "# Checklist - Fase 1"
  echo
  echo "- [x] Crear rama de evolución"
  echo "- [x] Congelar baseline actual"
  echo "- [x] Definir qué se queda"
  echo "- [x] Definir qué cambia"
  echo "- [x] Crear estructura base nueva del repo"
  echo "- [x] Preservar SQL actuales como referencia legacy"
  echo "- [x] Documentar arquitectura objetivo"
  echo "- [x] Definir siguiente paso práctico"
} > docs/phase1_checklist.md

echo "==> Generando siguiente paso..."
{
  echo "# Próximo paso después de Fase 1"
  echo
  echo "Implementar el primer Glue Job con Spark:"
  echo
  echo "- archivo: \`glue_jobs/pedidos_curated_job.py\`"
  echo "- objetivo: reemplazar la lógica de \`02_ctas_pedidos_curated.sql\`"
  echo "- salida: Parquet en \`s3://ejrp-g01-curated-ejrp/curated/pedidos_curated/\`"
  echo "- validación: Athena"
} > docs/phase1_next_step.md

if [ "$AUTO_COMMIT" = "true" ]; then
  echo "==> Haciendo commit automático..."
  git add dags glue_jobs sql docs scripts || true
  git commit -m "Define phase 1 keep vs change for MWAA + Glue Spark evolution"
else
  echo "==> AUTO_COMMIT=false, no se hizo commit automático."
fi

echo
echo "OK: Fase 1 preparada."
echo "Archivos creados:"
echo " - docs/phase1_inventory.md"
echo " - docs/phase1_keep_vs_change.md"
echo " - docs/phase1_checklist.md"
echo " - docs/phase1_next_step.md"
