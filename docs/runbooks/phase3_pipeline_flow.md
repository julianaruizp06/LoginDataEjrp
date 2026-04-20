# Runbook - Flujo objetivo del pipeline

## Flujo

```text
check_raw_files
    ↓
validate_raw_schema
    ↓
[run_glue_pedidos_curated, run_glue_sensores_curated]
    ↓
run_glue_dimensions
    ↓
refresh_glue_catalog
    ↓
run_athena_validation_queries
    ↓
run_athena_demo_queries
    ↓
notify_pipeline_status
```

## Notas

- Las validaciones deben ejecutarse antes de Spark.
- Athena ya no debe crear curated.
- Athena solo valida y demuestra.
- Glue Jobs escriben en Parquet sobre la capa curated.

