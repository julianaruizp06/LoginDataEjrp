#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-default}"
REGION="${REGION:-us-east-1}"
WORKGROUP="${WORKGROUP:-ejrp-g01-dev-wg}"
ATHENA_OUTPUT="${ATHENA_OUTPUT:-s3://ejrp-g01-athena-results-ejrp/athena-results/}"

require_auth() {
  echo "Validando credenciales AWS..."
  aws sts get-caller-identity --profile "$PROFILE" --region "$REGION" >/dev/null
  echo "OK: credenciales válidas"
}

split_sql_file() {
  python - "$1" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

clean_lines = []
for line in text.splitlines():
    stripped = line.lstrip()
    if stripped.startswith("--"):
        continue
    if "--" in line:
        line = line.split("--", 1)[0]
    clean_lines.append(line)

sql = "\n".join(clean_lines)
parts = [p.strip() for p in sql.split(";") if p.strip()]

for part in parts:
    print(part)
    print("__SQL_SPLIT__")
PY
}

run_statement() {
  local sql="$1"
  local label="$2"

  echo
  echo "Ejecutando: $label"

  local qid
  qid=$(
    aws athena start-query-execution \
      --profile "$PROFILE" \
      --region "$REGION" \
      --work-group "$WORKGROUP" \
      --query-string "$sql" \
      --result-configuration "OutputLocation=${ATHENA_OUTPUT}" \
      --query 'QueryExecutionId' \
      --output text
  )

  echo "QueryExecutionId: $qid"

  while true; do
    local state
    state=$(
      aws athena get-query-execution \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query-execution-id "$qid" \
        --query 'QueryExecution.Status.State' \
        --output text
    )

    case "$state" in
      SUCCEEDED)
        echo "OK: $label"
        break
        ;;
      FAILED|CANCELLED)
        echo "ERROR en $label"
        aws athena get-query-execution \
          --profile "$PROFILE" \
          --region "$REGION" \
          --query-execution-id "$qid" \
          --query 'QueryExecution.Status.StateChangeReason' \
          --output text
        exit 1
        ;;
      RUNNING|QUEUED)
        sleep 2
        ;;
      *)
        echo "Estado inesperado: $state"
        exit 1
        ;;
    esac
  done
}

run_sql_file() {
  local file="$1"
  local n=0
  local buffer=""

  while IFS= read -r line; do
    if [[ "$line" == "__SQL_SPLIT__" ]]; then
      if [[ -n "${buffer// }" ]]; then
        n=$((n+1))
        run_statement "$buffer" "$(basename "$file") [stmt $n]"
      fi
      buffer=""
    else
      if [[ -z "$buffer" ]]; then
        buffer="$line"
      else
        buffer="$buffer"$'\n'"$line"
      fi
    fi
  done < <(split_sql_file "$file")
}

require_auth

run_sql_file "sql/athena/00_create_databases.sql"
run_sql_file "sql/athena/01_raw_sanity_checks.sql"
run_sql_file "sql/athena/02_ctas_pedidos_curated.sql"
run_sql_file "sql/athena/03_ctas_sensores_curated.sql"
run_sql_file "sql/athena/04_ctas_dimensiones.sql"
