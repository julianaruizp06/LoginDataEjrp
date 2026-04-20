# Fase 3 - Arquitectura final propuesta

Fecha: 2026-04-18_18-33-13

## Objetivo

Definir la arquitectura final del proyecto para evolucionar desde una solución basada en Athena hacia una plataforma más completa, con orquestación formal, transformaciones escalables y trazabilidad operativa.

---

## Arquitectura final

```text
S3 raw
  ↓
MWAA (Airflow)
  ↓
Glue Jobs con Spark
  ↓
S3 curated en Parquet
  ↓
Glue Catalog
  ↓
Athena
  ↓
Queries de validación y demo
```

---

## Traducción práctica

- **MWAA** orquesta
- **Glue Spark** transforma
- **S3 curated** almacena resultados en Parquet
- **Glue Catalog** registra tablas
- **Athena** consulta, valida y demuestra

---

## Qué cambia respecto a la versión anterior

### Antes
- Athena construía la capa curated con CTAS
- la ejecución era semi-manual
- la observabilidad era básica

### Ahora
- MWAA controla el flujo de punta a punta
- Glue Jobs con Spark construyen curated
- Athena queda como capa de validación y demo
- los logs se ven en MWAA, Glue y CloudWatch

---

## Rol de cada componente

### S3 raw
Recibe los archivos fuente sin transformar.

### MWAA
Orquesta dependencias, reintentos, orden de ejecución y estado del pipeline.

### Glue Jobs con Spark
Implementan la lógica de transformación y escriben Parquet en curated.

### S3 curated
Almacena los outputs analíticos listos para consulta.

### Glue Catalog
Expone las tablas a Athena.

### Athena
Ejecuta validaciones técnicas, queries de negocio y demo.

---

## Tareas objetivo del DAG

1. check_raw_files
2. validate_raw_schema
3. run_glue_pedidos_curated
4. run_glue_sensores_curated
5. run_glue_dimensions
6. refresh_glue_catalog
7. run_athena_validation_queries
8. run_athena_demo_queries
9. notify_pipeline_status

---

## Resultado esperado

La capa curated ya no dependerá de CTAS en Athena.  
Athena se mantiene como capa de validación y consumo final.

---

## Próximo paso recomendado

Implementar el primer Glue Job:

- archivo: `glue_jobs/pedidos_curated_job.py`
- referencia funcional: `sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql`
- salida: Parquet en `s3://ejrp-g01-curated-ejrp/curated/pedidos_curated/`
- validación final: Athena

