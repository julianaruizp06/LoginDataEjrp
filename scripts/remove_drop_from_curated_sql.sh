#!/usr/bin/env bash
set -euo pipefail

echo "==> Quitando DROP TABLE del inicio de los CTAS curated..."

python - <<'PY'
from pathlib import Path
import re

files = [
    Path("sql/athena/02_ctas_pedidos_curated.sql"),
    Path("sql/athena/03_ctas_sensores_curated.sql"),
]

pattern = re.compile(r'^\s*DROP TABLE IF EXISTS .?;\s', re.IGNORECASE | re.DOTALL)

for path in files:
    text = path.read_text(encoding="utf-8", errors="ignore")
    new_text = pattern.sub("", text, count=1)
    path.write_text(new_text, encoding="utf-8", newline="\n")
    print(f"Procesado: {path}")
PY

echo
echo "==> Primeras líneas para validar:"
head -n 8 sql/athena/02_ctas_pedidos_curated.sql
echo
head -n 8 sql/athena/03_ctas_sensores_curated.sql
