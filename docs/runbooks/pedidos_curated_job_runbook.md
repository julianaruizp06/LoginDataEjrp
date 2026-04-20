# Runbook pedidos_curated

## Qué hace
- Lee datos raw
- Hace joins
- Calcula métricas
- Escribe en Parquet curated

## Output
s3://<bucket>/curated/pedidos_curated/

## Validación en Athena

SELECT COUNT(*) FROM logidata_curated.pedidos_curated;

SELECT * FROM logidata_curated.pedidos_curated LIMIT 20;
