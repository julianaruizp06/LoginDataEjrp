#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

ok()   { echo "[OK]   $1"; }
warn() { echo "[WARN] $1"; }
miss() { echo "[MISS] $1"; }
info() { echo "       $1"; }

exists_file() {
  local path="$1"
  [[ -f "$ROOT/$path" ]]
}

exists_dir() {
  local path="$1"
  [[ -d "$ROOT/$path" ]]
}

count_files() {
  local path="$1"
  find "$ROOT/$path" -type f 2>/dev/null | wc -l | tr -d ' '
}

check_dir_with_expected_files() {
  local dir="$1"
  shift
  local expected=("$@")

  echo
  echo "== Revisando: $dir =="

  if ! exists_dir "$dir"; then
    miss "No existe la carpeta $dir"
    return
  fi

  local total
  total=$(count_files "$dir")
  ok "Existe la carpeta $dir (${total} archivos)"

  local missing_any=0
  for f in "${expected[@]}"; do
    if exists_file "$f"; then
      ok "Archivo esperado presente: $f"
    else
      warn "Falta archivo esperado: $f"
      missing_any=1
    fi
  done

  if [[ "$missing_any" -eq 0 ]]; then
    ok "$dir cumple con lo esperado"
  else
    warn "$dir existe, pero le faltan algunos archivos esperados"
  fi
}

check_dir_has_some_files() {
  local dir="$1"
  local pattern_desc="$2"

  echo
  echo "== Revisando: $dir =="

  if ! exists_dir "$dir"; then
    miss "No existe la carpeta $dir"
    return
  fi

  local total
  total=$(count_files "$dir")
  if [[ "$total" -gt 0 ]]; then
    ok "Existe la carpeta $dir (${total} archivos)"
    info "Validación general: contiene archivos ${pattern_desc}"
  else
    warn "La carpeta $dir existe pero está vacía"
  fi
}

check_any_match_in_dir() {
  local dir="$1"
  local label="$2"
  shift 2
  local patterns=("$@")

  if ! exists_dir "$dir"; then
    miss "No existe la carpeta $dir"
    return
  fi

  local found=0
  for p in "${patterns[@]}"; do
    if find "$ROOT/$dir" -type f -name "$p" | grep -q .; then
      found=1
      break
    fi
  done

  if [[ "$found" -eq 1 ]]; then
    ok "$dir tiene al menos un archivo para: $label"
  else
    warn "$dir no tiene archivos para: $label"
  fi
}

echo "======================================"
echo "VALIDACIÓN DE ESTRUCTURA DEL REPOSITORIO"
echo "Base: $ROOT"
echo "======================================"

echo
echo "== Revisando raíz del repo =="

root_expected=(
  "README.md"
  ".gitignore"
  "requirements.txt"
  ".env.example"
)

for f in "${root_expected[@]}"; do
  if exists_file "$f"; then
    ok "Archivo raíz presente: $f"
  else
    warn "Falta archivo raíz esperado: $f"
  fi
done

if exists_file "docker-compose.yaml" || exists_file "docker-compose.yml"; then
  ok "Archivo de docker-compose presente"
else
  warn "No se encontró docker-compose.yaml / docker-compose.yml"
fi

# Core folders
check_dir_with_expected_files "dags" \
  "dags/logidata_pipeline_dag.py"

check_dir_has_some_files "glue_jobs" "(jobs Spark / Glue)"
check_any_match_in_dir "glue_jobs" "scripts Python de Glue" "*.py"

check_dir_has_some_files "sql" "(queries y validaciones SQL)"
check_any_match_in_dir "sql" "archivos SQL" "*.sql"

check_dir_has_some_files "src" "(módulos de negocio / ingest / observabilidad)"
check_any_match_in_dir "src" "archivos Python" "*.py"

check_dir_has_some_files "tests" "(tests automatizados)"
check_any_match_in_dir "tests" "archivos de test" "test_*.py" "*_test.py"

check_dir_has_some_files "docs" "(documentación)"
check_any_match_in_dir "docs" "archivos markdown" "*.md"

check_dir_has_some_files "diagrams" "(diagramas)"
check_any_match_in_dir "diagrams" "diagramas / imágenes" "*.png" "*.jpg" "*.jpeg" "*.svg" "*.drawio" "*.mmd"

check_dir_has_some_files "assets" "(datos o recursos)"
if exists_dir "assets/data"; then
  ok "Existe assets/data"
else
  warn "No existe assets/data"
fi

echo
echo "== Revisando Terraform =="

if exists_dir "infra/terraform"; then
  ok "Existe infra/terraform"
else
  miss "No existe infra/terraform"
fi

check_dir_has_some_files "infra/terraform/bootstrap" "(bootstrap terraform)"
check_any_match_in_dir "infra/terraform/bootstrap" "archivos terraform" "*.tf"

check_dir_has_some_files "infra/terraform/modules" "(módulos terraform)"
check_any_match_in_dir "infra/terraform/modules" "archivos terraform" "*.tf"

check_dir_has_some_files "infra/terraform/envs/dev" "(entorno dev)"
check_any_match_in_dir "infra/terraform/envs/dev" "archivos terraform" "*.tf" "*.tfvars"

check_dir_has_some_files "infra/terraform/envs/prod" "(entorno prod)"
check_any_match_in_dir "infra/terraform/envs/prod" "archivos terraform" "*.tf" "*.tfvars"

echo
echo "== Revisando contenido útil mínimo por subárea =="

# SQL subfolders
if exists_dir "sql/legacy_athena_ctas"; then
  ok "Existe sql/legacy_athena_ctas"
else
  warn "No existe sql/legacy_athena_ctas"
fi

if exists_dir "sql/validations"; then
  ok "Existe sql/validations"
else
  warn "No existe sql/validations"
fi

if exists_dir "sql/business_queries"; then
  ok "Existe sql/business_queries"
else
  warn "No existe sql/business_queries"
fi

# src subfolders
for d in "src/ingest" "src/observability" "src/config" "src/producers" "src/validators"; do
  if exists_dir "$d"; then
    ok "Existe $d"
    files=$(count_files "$d")
    if [[ "$files" -eq 0 ]]; then
      warn "$d existe pero está vacío"
    else
      info "$d contiene $files archivos"
    fi
  else
    warn "No existe $d"
  fi
done

echo
echo "== Revisando archivos vacíos dentro del core =="

find "$ROOT/dags" "$ROOT/glue_jobs" "$ROOT/sql" "$ROOT/src" "$ROOT/tests" "$ROOT/docs" "$ROOT/infra" \
  -type f -empty 2>/dev/null | sed 's#^#\[WARN\] Archivo vacío: #' || true

echo
echo "== Revisando archivos demasiado pequeños (< 40 bytes) en carpetas core =="

find "$ROOT/dags" "$ROOT/glue_jobs" "$ROOT/sql" "$ROOT/src" "$ROOT/tests" "$ROOT/docs" "$ROOT/infra" \
  -type f -size -40c 2>/dev/null | sed 's#^#\[WARN\] Archivo muy pequeño: #' || true

echo
echo "== Resumen sugerido =="
echo "1) Si una carpeta core no existe: crearla o ajustar el diseño."
echo "2) Si existe pero está vacía: revisar si es scaffold innecesario."
echo "3) Si faltan archivos esperados: validar si el repo quedó incompleto."
echo "4) Si hay archivos vacíos o demasiado pequeños: revisar si deben borrarse."

echo
echo "Validación terminada."
