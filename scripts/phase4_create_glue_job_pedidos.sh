#!/usr/bin/env bash
set -euo pipefail

echo "Creando Glue Job pedidos_curated..."

mkdir -p glue_jobs
mkdir -p docs/runbooks

cat > glue_jobs/pedidos_curated_job.py <<'PY'
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F

import sys

args = getResolvedOptions(sys.argv, ["JOB_NAME", "RAW_DB", "CURATED_BUCKET"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

logger = glueContext.get_logger()
logger.info("Iniciando job pedidos_curated")

raw_db = args["RAW_DB"]
bucket = args["CURATED_BUCKET"]

output_path = f"s3://{bucket}/curated/pedidos_curated/"

# Leer tablas
pedidos = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db,
    table_name="raw_local_pedidos"
).toDF()

entregas = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db,
    table_name="raw_local_entregas"
).toDF()

clientes = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db,
    table_name="raw_local_clientes"
).toDF()

catalogo = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db,
    table_name="raw_local_catalogo"
).toDF()

# Join principal
df = pedidos \
    .join(entregas, "id_pedido", "left") \
    .join(clientes, "id_cliente", "left") \
    .join(catalogo, "id_producto", "left")

# Transformaciones
df = df \
    .withColumn("fecha_pedido_ts", F.to_timestamp("fecha_pedido")) \
    .withColumn("periodo_ym", F.date_format("fecha_pedido_ts", "yyyy-MM")) \
    .withColumn(
        "cancelado_flag",
        F.when(F.upper(F.col("estado")).isin("CANCELADO", "ANULADO"), 1).otherwise(0)
    ) \
    .withColumn(
        "entrega_a_tiempo_flag",
        F.when(
            F.col("fecha_entrega_real") <= F.col("fecha_prometida_entrega"),
            1
        ).otherwise(0)
    )

# Escritura
df.write \
  .mode("overwrite") \
  .partitionBy("periodo_ym") \
  .parquet(output_path)

logger.info("Job completado")
job.commit()
PY

cat > docs/runbooks/pedidos_curated_job_runbook.md <<'DOC'
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
DOC

echo "OK: Glue job creado"
