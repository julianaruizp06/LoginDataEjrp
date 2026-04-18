#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-logidata}"
REGION="${REGION:-us-east-1}"

RAW_BUCKET="${RAW_BUCKET:-ejrp-g01-raw-ejrp}"
CURATED_BUCKET="${CURATED_BUCKET:-ejrp-g01-curated-ejrp}"
ATHENA_RESULTS_BUCKET="${ATHENA_RESULTS_BUCKET:-ejrp-g01-athena-results-ejrp}"

RAW_DB="${RAW_DB:-logidata_raw}"
CURATED_DB="${CURATED_DB:-logidata_curated}"
WORKGROUP="${WORKGROUP:-ejrp-g01-dev-wg}"

RUN_ATHENA_TEST="${RUN_ATHENA_TEST:-false}"
ATHENA_OUTPUT="${ATHENA_OUTPUT:-s3://${ATHENA_RESULTS_BUCKET}/athena-results/}"

REQUIRED_PREFIXES=(
  "raw/local/clientes/"
  "raw/local/catalogo/"
  "raw/local/entregas/"
  "raw/local/pedidos/"
  "raw/local/sensores/"
)

REQUIRED_TABLES=(
  "raw_local_clientes"
  "raw_local_catalogo"
  "raw_local_entregas"
  "raw_local_pedidos"
  "raw_local_sensores"
)

FAILURES=0

ok()   { echo "OK  $1"; }
warn() { echo "WARN $1"; }
fail() { echo "FAIL $1"; FAILURES=$((FAILURES+1)); }
info() { echo "-- $1"; }

check_bucket() {
  local bucket="$1"
  if aws s3api head-bucket --bucket "$bucket" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
    ok "Bucket encontrado: $bucket"
  else
    fail "Bucket no encontrado o sin acceso: $bucket"
  fi
}

check_prefix() {
  local bucket="$1"
  local prefix="$2"

  local count
  count=$(
    aws s3api list-objects-v2 \
      --bucket "$bucket" \
      --prefix "$prefix" \
      --profile "$PROFILE" \
      --region "$REGION" \
      --query 'length(Contents)' \
      --output text 2>/dev/null || echo "0"
  )

  if [[ "$count" == "None" || "$count" == "0" ]]; then
    fail "Prefijo vacío o inexistente: s3://${bucket}/${prefix}"
  else
    ok "Prefijo con archivos: s3://${bucket}/${prefix} (${count} objeto(s))"
  fi
}

check_glue_db() {
  local db="$1"
  if aws glue get-database --name "$db" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
    ok "Glue database encontrada: $db"
  else
    fail "Glue database no encontrada: $db"
  fi
}

check_glue_table() {
  local db="$1"
  local table="$2"
  if aws glue get-table --database-name "$db" --name "$table" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
    ok "Glue table encontrada: ${db}.${table}"
  else
    fail "Glue table no encontrada: ${db}.${table}"
  fi
}

check_workgroup() {
  local wg="$1"
  if aws athena get-work-group --work-group "$wg" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
    ok "Athena workgroup encontrado: $wg"
  else
    fail "Athena workgroup no encontrado: $wg"
  fi
}

run_athena_test() {
  info "Ejecutando prueba simple de Athena..."

  local query_id
  query_id=$(
    aws athena start-query-execution \
      --profile "$PROFILE" \
      --region "$REGION" \
      --work-group "$WORKGROUP" \
      --query-string "SHOW TABLES IN ${RAW_DB};" \
      --result-configuration "OutputLocation=${ATHENA_OUTPUT}" \
      --query 'QueryExecutionId' \
      --output text
  )

  while true; do
    local state
    state=$(
      aws athena get-query-execution \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query-execution-id "$query_id" \
        --query 'QueryExecution.Status.State' \
        --output text
    )

    case "$state" in
      SUCCEEDED)
        ok "Athena query ejecutada correctamente"
        break
        ;;
      FAILED|CANCELLED)
        local reason
        reason=$(
          aws athena get-query-execution \
            --profile "$PROFILE" \
            --region "$REGION" \
            --query-execution-id "$query_id" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text
        )
        fail "Athena query falló: ${reason}"
        break
        ;;
      QUEUED|RUNNING)
        sleep 2
        ;;
      *)
        fail "Estado inesperado de Athena: ${state}"
        break
        ;;
    esac
  done
}

info "Validando identidad AWS..."
aws sts get-caller-identity --profile "$PROFILE" --region "$REGION" >/dev/null
ok "Credenciales AWS válidas"

info "Validando buckets..."
check_bucket "$RAW_BUCKET"
check_bucket "$CURATED_BUCKET"
check_bucket "$ATHENA_RESULTS_BUCKET"

info "Validando prefijos raw en S3..."
for prefix in "${REQUIRED_PREFIXES[@]}"; do
  check_prefix "$RAW_BUCKET" "$prefix"
done

info "Validando Glue databases..."
check_glue_db "$RAW_DB"
check_glue_db "$CURATED_DB"

info "Validando tablas raw en Glue..."
for table in "${REQUIRED_TABLES[@]}"; do
  check_glue_table "$RAW_DB" "$table"
done

info "Validando Athena workgroup..."
check_workgroup "$WORKGROUP"

if [[ "$RUN_ATHENA_TEST" == "true" ]]; then
  run_athena_test
else
  warn "Prueba de Athena omitida. Usa RUN_ATHENA_TEST=true para activarla."
fi

if [[ "$FAILURES" -eq 0 ]]; then
  echo
  echo "VALIDACION EXITOSA"
else
  echo
  echo "VALIDACION CON ERRORES: ${FAILURES}"
  exit 1
fi
