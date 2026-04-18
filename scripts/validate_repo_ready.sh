#!/usr/bin/env bash
set -euo pipefail

EXPECTED_BRANCH="${EXPECTED_BRANCH:-feature/mwaa-glue-spark-evolution}"
STRICT_BRANCH="${STRICT_BRANCH:-false}"

FAILURES=0

ok()   { echo "OK   $1"; }
warn() { echo "WARN $1"; }
fail() { echo "FAIL $1"; FAILURES=$((FAILURES+1)); }
info() { echo "--   $1"; }

check_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    ok "Directorio existe: $path"
  else
    fail "Directorio faltante: $path"
  fi
}

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    ok "Archivo existe: $path"
  else
    fail "Archivo faltante: $path"
  fi
}

check_absent_file() {
  local path="$1"
  if [[ -e "$path" ]]; then
    fail "No debería existir: $path"
  else
    ok "Ausencia correcta: $path"
  fi
}

check_athena_dir_clean() {
  if [[ -d "sql/athena" ]]; then
    if find sql/athena -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
      fail "sql/athena existe y todavía tiene archivos"
    else
      ok "sql/athena existe pero está vacío"
    fi
  else
    ok "sql/athena ya no existe"
  fi
}

info "Validando que estás dentro de un repo Git..."
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "Repositorio Git detectado"
else
  fail "No estás dentro de un repositorio Git"
  echo
  echo "VALIDACION CON ERRORES: $FAILURES"
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current || true)"
info "Rama actual: ${CURRENT_BRANCH:-desconocida}"

if [[ "$STRICT_BRANCH" == "true" ]]; then
  if [[ "$CURRENT_BRANCH" == "$EXPECTED_BRANCH" ]]; then
    ok "Rama esperada activa: $EXPECTED_BRANCH"
  else
    fail "Rama actual '$CURRENT_BRANCH' no coincide con '$EXPECTED_BRANCH'"
  fi
else
  warn "Validación estricta de rama desactivada"
fi

echo
info "Validando estructura base del repo..."
check_dir "dags"
check_dir "glue_jobs"
check_dir "glue_jobs/utils"
check_dir "sql"
check_dir "sql/validations"
check_dir "sql/business_queries"
check_dir "sql/legacy_athena_ctas"
check_dir "docs"
check_dir "docs/runbooks"
check_dir "tests"

echo
info "Validando archivos clave..."
check_file "dags/README.md"
check_file "glue_jobs/README.md"
check_file "glue_jobs/utils/README.md"
check_file "docs/runbooks/README.md"
check_file "tests/README.md"
check_file "docs/phase1_keep_vs_change.md"
check_file "docs/phase1_checklist.md"
check_file "docs/phase1_next_step.md"
check_file "docs/phase2_repo_reorganized.md"

echo
info "Validando SQL en ubicaciones esperadas..."
check_file "sql/validations/raw_sanity_checks.sql"
check_file "sql/validations/create_vw_pedidos_unificados.sql"
check_file "sql/business_queries/insights.sql"

check_file "sql/legacy_athena_ctas/00_create_databases.sql"
check_file "sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql"
check_file "sql/legacy_athena_ctas/03_ctas_sensores_curated.sql"
check_file "sql/legacy_athena_ctas/04_ctas_dimensiones.sql"

echo
info "Validando que no haya duplicados incorrectos en legacy..."
check_absent_file "sql/legacy_athena_ctas/01_raw_sanity_checks.sql"
check_absent_file "sql/legacy_athena_ctas/05_view_pedidos_unificados.sql"
check_absent_file "sql/legacy_athena_ctas/06_insights.sql"

echo
info "Validando carpeta SQL antigua..."
check_athena_dir_clean

echo
info "Resumen de git status..."
git status --short || true

echo
if [[ "$FAILURES" -eq 0 ]]; then
  echo "VALIDACION EXITOSA: el repo quedó listo para continuar con MWAA + Glue + Spark."
else
  echo "VALIDACION CON ERRORES: $FAILURES"
  exit 1
fi
