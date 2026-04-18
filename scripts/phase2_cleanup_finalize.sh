#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] $*"
  else
    eval "$@"
  fi
}

echo "==> Limpiando backups temporales no deseados..."
run_cmd "rm -rf .phase2_backup"
run_cmd "rm -rf backup_sql_athena_*"

echo "==> Eliminando duplicados que no deben quedar en legacy..."
run_cmd "rm -f sql/legacy_athena_ctas/01_raw_sanity_checks.sql"
run_cmd "rm -f sql/legacy_athena_ctas/05_view_pedidos_unificados.sql"
run_cmd "rm -f sql/legacy_athena_ctas/06_insights.sql"

echo "==> Quitando staging previo para rehacer staging limpio..."
run_cmd "git restore --staged . || true"

echo "==> Agregando estructura final correcta..."
run_cmd "git add dags glue_jobs sql docs tests scripts"

echo
echo "==> Estado actual:"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY_RUN] git status --short"
else
  git status --short
fi

echo
echo "OK: limpieza de Fase 2 completada."
echo "Revisa git status y luego haz el commit."
