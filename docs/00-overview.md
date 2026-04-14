# LogiData Lakehouse (EJRP) — Architecture Skeleton

## 1) Contexto y objetivo
- **Situación:** LogiData S.A.S. centraliza datos dispersos (CSV + eventos IoT).
- **Objetivo:** Lakehouse en AWS con **SQL unificado**, **costos optimizados**, **seguridad** y **observabilidad**.
- **Alcance:** 4 fases (Foundations / Ingesta / Curación / Consumo & Gobierno)

## 2) Naming estándar
- Prefix: \$Prefix\
- Grupo: \g\
- Ambiente: \$Env\
- Región: \$Region\

Buckets estándar (sin ambiente):
- \$Prefix-g-raw\
- \$Prefix-g-curated\
- \$Prefix-g-athena-results\

Recursos con ambiente:
- \$Prefix-g--*\

## 3) Layout S3 (single source of truth)
> Nota: en S3 “carpetas” = prefijos.

### RAW
\\\	ext
s3://<raw-bucket>/raw/<source>/<dataset>/ingest_date=YYYY-MM-DD/<files>
\\\

### CURATED
\\\	ext
s3://<curated-bucket>/curated/<domain>/<dataset>/event_date=YYYY-MM-DD/<files_parquet>
\\\

### QUARANTINE
\\\	ext
s3://<raw-bucket>/quarantine/<source>/<dataset>/ingest_date=YYYY-MM-DD/batch_id=<id>/records.jsonl
\\\

### SYSTEM (metadata)
\\\	ext
s3://<raw-bucket>/_system/metadata/manifests/<dataset>/manifest_<batch_id>.json
\\\

## 4) Data Contracts + evolución
- Contratos: \docs/data-contracts/<dataset>.v1.json\
- Metadata mínima: \source\, \dataset\, \ingest_ts\, \atch_id\, \schema_version\
- Evolución: columnas nuevas OK; cambios de tipo/remoción ⇒ nueva versión + tests.

## 5) Quarantine + evidencia
- Quarantine si: missing required / type mismatch / invalid value.
- Evidencia:
  - \evidence/logs/*.jsonl\
  - \evidence/samples/quarantine/...\
  - \evidence/monitoring/metrics.json\

## 6) CI/CD
- PR no mergea si falla: pytest + terraform fmt/validate.

## 7) Terraform (módulos)
- bootstrap (state + lock), envs (dev/prod), modules (naming/s3/iam/kinesis/firehose/athena/glue)

## 8) DoD
- Layout documentado y aplicado
- Contratos v1 (mínimo 2 datasets)
- Quarantine + observabilidad (logs/métricas)
- CI verde
- Infra reproducible (terraform plan/apply)