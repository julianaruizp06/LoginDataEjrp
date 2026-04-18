#!/usr/bin/env bash
set -euo pipefail

echo "==> Limpiando staging previo..."
git restore --staged . || true

echo "==> Eliminando carpeta sql/athena si aún existe..."
if [ -d "sql/athena" ]; then
  rm -rf sql/athena
fi

echo "==> Eliminando backup viejo del repo..."
if [ -d "backup_sql_athena_20260417_154926" ]; then
  rm -rf backup_sql_athena_20260417_154926
fi

echo "==> Eliminando backups temporales locales..."
rm -rf .phase2_backup
rm -rf backup_sql_athena_*

echo "==> Agregando estructura final correcta..."
git add dags glue_jobs sql docs tests scripts

echo
echo "==> Estado actual:"
git status --short

echo
echo "OK: limpieza aplicada."
echo "Siguiente paso: volver a correr scripts/validate_repo_ready.sh"
