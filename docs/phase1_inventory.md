# Inventario del estado actual

Fecha: 2026-04-18_17-47-53

## Rama actual
feature/mwaa-glue-spark-evolution

## Estructura principal
.
./.git
./.git/hooks
./.git/info
./.git/logs
./.git/objects
./.git/refs
./.github
./.github/workflows
./.vscode
./assets
./assets/data
./backup_sql_athena_20260417_154926
./dags
./diagrams
./docs
./docs/data-contracts
./docs/docs
./evidence
./evidence/logs
./evidence/monitoring
./evidence/samples
./glue_jobs
./glue_jobs/utils
./infra
./infra/terraform
./scripts
./scripts/scripts
./sql
./sql/athena
./sql/business_queries
./sql/legacy_athena_ctas
./sql/validations
./src
./src/config
./src/ingest
./src/observability
./src/producers
./src/validators
./tests
./tests/integration
./tests/unit

## Archivos SQL actuales
sql/athena/00_create_databases.sql
sql/athena/01_raw_sanity_checks.sql
sql/athena/02_ctas_pedidos_curated.sql
sql/athena/03_ctas_sensores_curated.sql
sql/athena/04_ctas_dimensiones.sql
sql/athena/05_view_pedidos_unificados.sql
sql/athena/06_insights.sql
sql/legacy_athena_ctas/00_create_databases.sql
sql/legacy_athena_ctas/01_raw_sanity_checks.sql
sql/legacy_athena_ctas/02_ctas_pedidos_curated.sql
sql/legacy_athena_ctas/03_ctas_sensores_curated.sql
sql/legacy_athena_ctas/04_ctas_dimensiones.sql
sql/legacy_athena_ctas/05_view_pedidos_unificados.sql
sql/legacy_athena_ctas/06_insights.sql
