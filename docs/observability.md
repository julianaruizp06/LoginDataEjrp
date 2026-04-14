# Observabilidad (MVP)

## Logs (JSONL)
Campos mínimos:
- ts_utc, level, component, dataset, batch_id, message
Opcional: counters (records_read, records_valid, records_quarantined, duration_ms)

Destino local:
evidence/logs/<component>.jsonl

## Métricas (por batch)
- records_read, records_valid, records_quarantined, duration_ms, error_count

Destino local:
evidence/monitoring/metrics.json