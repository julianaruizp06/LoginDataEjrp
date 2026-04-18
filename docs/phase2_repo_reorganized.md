# Fase 2 - Repo reorganizado

## Qué se mantiene
- Infraestructura Terraform
- Buckets S3 actuales
- Glue Catalog
- Athena como capa de validación y demo
- Queries de negocio ya validadas

## Qué cambia
- Airflow/MWAA orquesta
- Glue Jobs con Spark transforman
- Parquet vive en curated
- Los CTAS antiguos quedan como referencia legacy

## Nuevo mapa
- `sql/legacy_athena_ctas/`: SQL antiguos usados como referencia
- `sql/validations/`: validaciones y creación de vista
- `sql/business_queries/`: queries finales de negocio
- `dags/`: orquestación MWAA
- `glue_jobs/`: transformaciones Spark

