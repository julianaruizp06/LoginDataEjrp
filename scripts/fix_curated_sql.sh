#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

CURATED_BUCKET="${CURATED_BUCKET:-ejrp-g01-curated-ejrp}"

BACKUP_DIR="backup_sql_athena_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp sql/athena/*.sql "$BACKUP_DIR"/

echo "Backup creado en: $BACKUP_DIR"

for f in sql/athena/*.sql; do
  perl -0pi -e "
    s/logidata_raw\.clientes\b/logidata_raw.raw_local_clientes/g;
    s/logidata_raw\.catalogo\b/logidata_raw.raw_local_catalogo/g;
    s/logidata_raw\.entregas\b/logidata_raw.raw_local_entregas/g;
    s/logidata_raw\.pedidos\b/logidata_raw.raw_local_pedidos/g;
    s/logidata_raw\.sensores\b/logidata_raw.raw_local_sensores/g;

    s#s3:///pedidos_curated/#s3://${CURATED_BUCKET}/curated/pedidos_curated/#g;
    s#s3:///sensores_curated/#s3://${CURATED_BUCKET}/curated/sensores_curated/#g;
    s#s3:///dim_cliente/#s3://${CURATED_BUCKET}/curated/dim_cliente/#g;
    s#s3:///dim_producto/#s3://${CURATED_BUCKET}/curated/dim_producto/#g;
    s#s3:///dim_vehiculo/#s3://${CURATED_BUCKET}/curated/dim_vehiculo/#g;
    s#s3:///dim_fecha/#s3://${CURATED_BUCKET}/curated/dim_fecha/#g;
  " "$f"
done

echo
echo "Validando que no queden referencias viejas..."

if grep -RInE 'logidata_raw\.(clientes|catalogo|entregas|pedidos|sensores)\b|s3:///' sql/athena; then
  echo
  echo "ERROR: quedaron referencias viejas en sql/athena"
  exit 1
fi

echo "OK: SQL corregidos"
echo
git diff -- sql/athena || true
