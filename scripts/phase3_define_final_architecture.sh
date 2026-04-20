#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
DATE_NOW="$(date +%Y-%m-%d_%H-%M-%S)"

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] $*"
  else
    eval "$@"
  fi
}

check_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "ERROR: falta el directorio requerido: $path"
    echo "Primero completa la Fase 2."
    exit 1
  fi
}

write_file() {
  local path="$1"
  shift
  run_cmd "mkdir -p \"$(dirname "$path")\""
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] write file: $path"
  else
    cat > "$path" <<EOF
$*
EOF
  fi
}

echo "==> Validando estructura mínima de Fase 2..."
check_dir "dags"
check_dir "glue_jobs"
check_dir "glue_jobs/utils"
check_dir "sql/validations"
check_dir "sql/business_queries"
check_dir "sql/legacy_athena_ctas"
check_dir "docs"
check_dir "docs/runbooks"

echo "==> Generando documentación de arquitectura final..."

write_file "docs/phase3_final_architecture.md" "# Fase 3 - Arquitectura final propuesta

Fecha: ${DATE_NOW}

## Objetivo

Definir la arquitectura final del proyecto para evolucionar desde una solución basada en Athena hacia una plataforma más completa, con orquestación formal, transformaciones escalables y trazabilidad operativa.

---

## Arquitectura final

\`\`\`text
S3 raw
  ↓
MWAA (Airflow)
  ↓
Glue Jobs con Spark
  ↓
S3 curated en Parquet
  ↓
Glue Catalog
  ↓
Athena
  ↓
Queries de validación y demo
\`\`\`

---

## Traducción práctica

- **MWAA** orquesta
- **Glue Spark** transforma
- **S3 curated** almacena resultados en Parquet
- **Glue Catalog** registra tablas
- **Athena** consulta, valida y demuestra

---

## Qué cambia respecto a la versión anterior

### Antes
- Athena construía la capa curated con CTAS
- la ejecución era semi-manual
- la observabilidad era básica

### Ahora
- MWAA controla el flujo de punta a punta
- Glue Jobs con Spark construyen curated
- Athena queda como capa de validación y demo
- los logs se ven en MWAA, Glue y CloudWatch

---

## Rol de cada componente

### S3 raw
Recibe los archivos fuente sin transformar.

### MWAA
Orquesta dependencias, reintentos, orden de ejecución y estado del pipeline.

### Glue Jobs con Spark
Implementan la lógica de transformación y escriben Parquet en curated.

### S3 curated
Almacena los outputs analíticos listos para consulta.

### Glue Catalog
Expone las tablas a Athena.

### Athena
Ejecuta validaciones técnicas, queries de negocio y demo.

---

## Tareas objetivo del DAG

1. check_raw_files
2. validate_raw_schema
3. run_glue_pedidos_curated
4. run_glue_sensores_curated
5. run_glue_dimensions
6. refresh_glue_catalog
7. run_athena_validation_queries
8. run_athena_demo_queries
9. notify_pipeline_status

---

## Resultado esperado

La capa curated ya no dependerá de CTAS en Athena.  
Athena se mantiene como capa de validación y consumo final.

---

## Próximo paso recomendado

Implementar el primer Glue Job:

- archivo: \`glue_jobs/pedidos_curated_job.py\`
- referencia funcional: \`sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql\`
- salida: Parquet en \`s3://ejrp-g01-curated-ejrp/curated/pedidos_curated/\`
- validación final: Athena
"

write_file "docs/runbooks/phase3_pipeline_flow.md" "# Runbook - Flujo objetivo del pipeline

## Flujo

\`\`\`text
check_raw_files
    ↓
validate_raw_schema
    ↓
[run_glue_pedidos_curated, run_glue_sensores_curated]
    ↓
run_glue_dimensions
    ↓
refresh_glue_catalog
    ↓
run_athena_validation_queries
    ↓
run_athena_demo_queries
    ↓
notify_pipeline_status
\`\`\`

## Notas

- Las validaciones deben ejecutarse antes de Spark.
- Athena ya no debe crear curated.
- Athena solo valida y demuestra.
- Glue Jobs escriben en Parquet sobre la capa curated.
"

write_file "docs/runbooks/phase3_component_responsibilities.md" "# Responsabilidades por componente

## MWAA
- orquestación
- dependencias
- retries
- control de fallos
- logs por tarea

## Glue Jobs con Spark
- lectura desde raw
- tipado
- joins
- reglas de negocio
- escritura en Parquet

## S3 curated
- almacenamiento final de tablas analíticas

## Glue Catalog
- publicación de tablas para Athena

## Athena
- validaciones
- queries de negocio
- demo
"

echo "==> Creando placeholders técnicos..."

write_file "dags/logidata_pipeline_dag.py" "\"\"\"DAG placeholder para MWAA / Airflow.

Fase actual:
- arquitectura definida
- implementación pendiente

Tareas objetivo:
1. check_raw_files
2. validate_raw_schema
3. run_glue_pedidos_curated
4. run_glue_sensores_curated
5. run_glue_dimensions
6. refresh_glue_catalog
7. run_athena_validation_queries
8. run_athena_demo_queries
9. notify_pipeline_status
\"\"\"

# TODO:
# Implementar DAG real en la siguiente fase.
"

write_file "glue_jobs/pedidos_curated_job.py" "\"\"\"Glue Job placeholder: pedidos_curated

Referencia funcional:
- sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql

Objetivo:
- leer raw pedidos, entregas, clientes y catálogo
- aplicar tipado y joins
- calcular flags y métricas derivadas
- escribir Parquet en curated
\"\"\"

# TODO:
# Implementar job real en la siguiente fase.
"

write_file "glue_jobs/sensores_curated_job.py" "\"\"\"Glue Job placeholder: sensores_curated

Referencia funcional:
- sql/legacy_athena_ctas/03_ctas_sensores_curated.sql

Objetivo:
- leer sensores raw
- tipar campos
- calcular temp_critica_flag y severidad_temperatura
- escribir Parquet en curated
\"\"\"

# TODO:
# Implementar job real en la siguiente fase.
"

write_file "glue_jobs/dimensions_job.py" "\"\"\"Glue Job placeholder: dimensions_job

Referencia funcional:
- sql/legacy_athena_ctas/04_ctas_dimensiones.sql

Objetivo:
- construir dim_cliente
- construir dim_producto
- construir dim_vehiculo
- construir dim_fecha
\"\"\"

# TODO:
# Implementar job real en la siguiente fase.
"

write_file "docs/phase3_checklist.md" "# Checklist - Fase 3

- [x] Definir arquitectura final
- [x] Documentar responsabilidades por componente
- [x] Documentar flujo objetivo del DAG
- [x] Crear placeholder del DAG
- [x] Crear placeholders de Glue Jobs
- [x] Dejar claro que Athena valida y demuestra
- [x] Dejar claro que Spark construye curated
"

echo "==> Agregando archivos al repo..."
run_cmd "git add dags glue_jobs docs scripts || true"

echo
echo "OK: Fase 3 preparada."
echo
echo "Archivos creados:"
echo " - docs/phase3_final_architecture.md"
echo " - docs/runbooks/phase3_pipeline_flow.md"
echo " - docs/runbooks/phase3_component_responsibilities.md"
echo " - docs/phase3_checklist.md"
echo " - dags/logidata_pipeline_dag.py"
echo " - glue_jobs/pedidos_curated_job.py"
echo " - glue_jobs/sensores_curated_job.py"
echo " - glue_jobs/dimensions_job.py"
echo
echo "Siguiente paso recomendado:"
echo " - implementar glue_jobs/pedidos_curated_job.py"
