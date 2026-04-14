# Quarantine Policy (MVP)

## Regla
Un registro va a quarantine si:
1) Falta un campo requerido (required_fields)
2) Tipo inválido (field_types)
3) Valor fuera de allowed_values

## Formato (JSONL)
Cada línea:
- dataset, source, schema_version
- batch_id, ingest_ts
- reason[] (lista)
- raw_record (el registro original)

## Layout local (evidence)
evidence/samples/quarantine/<dataset>/ingest_date=YYYY-MM-DD/batch_id=<id>/records.jsonl

## Layout en S3 (cuando AWS esté listo)
s3://<raw-bucket>/quarantine/<source>/<dataset>/ingest_date=YYYY-MM-DD/batch_id=<id>/records.jsonl