#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
DATE_NOW="$(date +%Y-%m-%d_%H-%M-%S)"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$PWD"
fi

cd "$REPO_ROOT"

BACKUP_DIR=".phase2_backup/${DATE_NOW}"
mkdir -p "$BACKUP_DIR"

log() {
  echo "==> $*"
}

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] $*"
  else
    eval "$@"
  fi
}

is_tracked() {
  git ls-files --error-unmatch "$1" >/dev/null 2>&1
}

backup_path() {
  local src="$1"
  if [[ -e "$src" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$src")"
    cp -a "$src" "$BACKUP_DIR/$src"
  fi
}

remove_path() {
  local src="$1"
  [[ -e "$src" ]] || return 0
  backup_path "$src"

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && is_tracked "$src"; then
    run_cmd "git rm -r -f \"$src\""
  else
    run_cmd "rm -rf \"$src\""
  fi
}

move_path() {
  local src="$1"
  local dest="$2"

  [[ -e "$src" ]] || return 0

  if [[ -e "$dest" ]]; then
    backup_path "$dest"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && is_tracked "$dest"; then
      run_cmd "git rm -r -f \"$dest\""
    else
      run_cmd "rm -rf \"$dest\""
    fi
  fi

  run_cmd "mkdir -p \"$(dirname "$dest")\""

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && is_tracked "$src"; then
    run_cmd "git mv \"$src\" \"$dest\""
  else
    run_cmd "mv \"$src\" \"$dest\""
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

log "Repo root: $REPO_ROOT"
log "Backup local: $BACKUP_DIR"

log "Creando estructura nueva..."
run_cmd "mkdir -p dags"
run_cmd "mkdir -p glue_jobs/utils"
run_cmd "mkdir -p sql/validations"
run_cmd "mkdir -p sql/business_queries"
run_cmd "mkdir -p sql/legacy_athena_ctas"
run_cmd "mkdir -p docs/runbooks"
run_cmd "mkdir -p tests"

log "Moviendo SQL actuales a la nueva estructura..."

move_path "sql/athena/00_create_databases.sql" "sql/legacy_athena_ctas/00_create_databases.sql"
move_path "sql/athena/01_raw_sanity_checks.sql" "sql/validations/raw_sanity_checks.sql"
move_path "sql/athena/02_ctas_pedidos_curated.sql" "sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql"
move_path "sql/athena/03_ctas_sensores_curated.sql" "sql/legacy_athena_ctas/03_ctas_sensores_curated.sql"
move_path "sql/athena/04_ctas_dimensiones.sql" "sql/legacy_athena_ctas/04_ctas_dimensiones.sql"
move_path "sql/athena/05_view_pedidos_unificados.sql" "sql/validations/create_vw_pedidos_unificados.sql"
move_path "sql/athena/06_insights.sql" "sql/business_queries/insights.sql"

log "Creando placeholders nuevos..."
write_file "dags/README.md" "# DAGs de MWAA

Aquí vivirán los DAGs de Airflow/MWAA.

Archivo inicial sugerido:
- \`logidata_pipeline_dag.py\`
"

write_file "glue_jobs/README.md" "# Glue Jobs con Spark

Aquí vivirán los jobs de Spark/Glue.

Jobs sugeridos:
- \`pedidos_curated_job.py\`
- \`sensores_curated_job.py\`
- \`dimensions_job.py\`
"

write_file "glue_jobs/utils/README.md" "# Utilidades compartidas

Aquí vivirán helpers de lectura, validación y escritura para los Glue Jobs.
"

write_file "docs/runbooks/README.md" "# Runbooks

Aquí vivirán los runbooks operativos de MWAA, Glue Jobs y validaciones.
"

write_file "tests/README.md" "# Tests

Espacio para pruebas de validación y transformaciones.
"

write_file "docs/phase2_repo_reorganized.md" "# Fase 2 - Repo reorganizado

## Qué se mantiene
- Infraestructura Terraform
- Buckets S3 actuales
- Glue Catalog
- Athena como capa de validación y demo
- Queries de negocio ya validadas

## Qué cambia
- Airflow/MWAA orquesta
- Glue Jobs con Spark transforman
- Parquet vive en curated
- Los CTAS antiguos quedan como referencia legacy

## Nuevo mapa
- \`sql/legacy_athena_ctas/\`: SQL antiguos usados como referencia
- \`sql/validations/\`: validaciones y creación de vista
- \`sql/business_queries/\`: queries finales de negocio
- \`dags/\`: orquestación MWAA
- \`glue_jobs/\`: transformaciones Spark
"

log "Eliminando scripts obsoletos del repo activo..."
OBSOLETE_PATHS=(
  "scripts/run_athena_sql.sh"
  "scripts/run_athena_05_06.sh"
  "scripts/run_athena_ctas_only.sh"
  "scripts/check_counts.sh"
  "scripts/fix_curated_sql.sh"
  "scripts/fix_athena_workgroup_ctas.sh"
  "scripts/fix_and_run_curated.sh"
)

for p in "${OBSOLETE_PATHS[@]}"; do
  remove_path "$p"
done

log "Eliminando backups temporales viejos dentro del repo..."
shopt -s nullglob
for d in backup_sql_athena_*; do
  remove_path "$d"
done
shopt -u nullglob

log "Eliminando carpeta sql/athena si quedó vacía..."
if [[ -d "sql/athena" ]] && [[ -z "$(find sql/athena -mindepth 1 -print -quit 2>/dev/null)" ]]; then
  remove_path "sql/athena"
fi

log "Resumen final..."
echo
echo "Nueva estructura relevante:"
echo " - dags/"
echo " - glue_jobs/"
echo " - sql/validations/"
echo " - sql/business_queries/"
echo " - sql/legacy_athena_ctas/"
echo " - docs/runbooks/"
echo " - tests/"
echo
echo "Backup local creado en:"
echo " - $BACKUP_DIR"
echo
echo "Siguiente paso recomendado:"
echo " - crear glue_jobs/pedidos_curated_job.py"
echo " - reutilizar la lógica de sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql"
echo
echo "OK: Fase 2 completada."
