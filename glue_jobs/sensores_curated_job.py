import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

# ============================================================
# Job: sensores_curated
# Lee raw, valida schema y calidad mínima, separa inválidos,
# escribe válidos en curated e inválidos en quarantine.
# ============================================================

args = getResolvedOptions(sys.argv, ["JOB_NAME", "RAW_DB", "CURATED_BUCKET"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

logger = glueContext.get_logger()
logger.info("Iniciando job sensores_curated")

raw_db = args["RAW_DB"]
bucket = args["CURATED_BUCKET"]

output_path = f"s3://{bucket}/curated/sensores_curated/"
quarantine_path = f"s3://{bucket}/quarantine/sensores_curated/"

# ============================================================
# 1. Leer tabla raw
# ============================================================

df_sensores = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db,
    table_name="raw_local_sensores"
).toDF()

row_count_raw = df_sensores.count()
logger.info(f"Registros encontrados en RAW: {row_count_raw}")
logger.info(f"Columnas detectadas: {df_sensores.columns}")

# ============================================================
# 2. Validación de schema crítico
# Si falta una columna obligatoria, falla el job completo.
# ============================================================

required_columns_sensores = [
    "vehiculo",
    "timestamp",
    "latitud",
    "longitud",
    "temperatura",
    "evento"
]

def validate_required_columns(df, required_cols, df_name):
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise Exception(f"Schema inválido en {df_name}. Columnas faltantes: {missing}")

validate_required_columns(df_sensores, required_columns_sensores, "raw_local_sensores")

# ============================================================
# 3. Parseo / normalización y validaciones
# ============================================================

valid_events = ["OK", "TEMP_CRITICA"]

df_validated = (
    df_sensores
    .withColumn("timestamp_ts", F.to_timestamp("timestamp"))
    .withColumn("latitud_num", F.col("latitud").cast("double"))
    .withColumn("longitud_num", F.col("longitud").cast("double"))
    .withColumn("temperatura_num", F.col("temperatura").cast("double"))
    .withColumn(
        "validation_error",
        F.when(
            F.col("vehiculo").isNull() | (F.trim(F.col("vehiculo")) == ""),
            F.lit("vehiculo vacío")
        )
        .when(
            F.col("timestamp").isNull() | (F.trim(F.col("timestamp")) == ""),
            F.lit("timestamp vacío")
        )
        .when(
            F.col("timestamp_ts").isNull(),
            F.lit("timestamp inválido")
        )
        .when(
            F.col("latitud_num").isNull(),
            F.lit("latitud inválida")
        )
        .when(
            (F.col("latitud_num") < -90) | (F.col("latitud_num") > 90),
            F.lit("latitud fuera de rango")
        )
        .when(
            F.col("longitud_num").isNull(),
            F.lit("longitud inválida")
        )
        .when(
            (F.col("longitud_num") < -180) | (F.col("longitud_num") > 180),
            F.lit("longitud fuera de rango")
        )
        .when(
            F.col("temperatura_num").isNull(),
            F.lit("temperatura inválida")
        )
        .when(
            (F.col("temperatura_num") < -50) | (F.col("temperatura_num") > 80),
            F.lit("temperatura fuera de rango físico")
        )
        .when(
            F.col("evento").isNull() | (~F.upper(F.col("evento")).isin(valid_events)),
            F.lit("evento inválido")
        )
    )
)

# ============================================================
# 4. Detectar duplicados
# Duplicado por vehiculo + timestamp + evento
# ============================================================

duplicate_keys = (
    df_validated
    .groupBy("vehiculo", "timestamp", "evento")
    .count()
    .filter(F.col("count") > 1)
    .select("vehiculo", "timestamp", "evento")
)

df_validated = (
    df_validated
    .join(
        duplicate_keys.withColumn("duplicate_flag", F.lit(1)),
        on=["vehiculo", "timestamp", "evento"],
        how="left"
    )
    .withColumn(
        "validation_error",
        F.when(
            F.col("validation_error").isNull() & (F.col("duplicate_flag") == 1),
            F.lit("registro duplicado")
        ).otherwise(F.col("validation_error"))
    )
)

# ============================================================
# 5. Separar válidos / inválidos
# ============================================================

df_invalid = df_validated.filter(F.col("validation_error").isNotNull())
df_valid = df_validated.filter(F.col("validation_error").isNull())

invalid_count = df_invalid.count()
valid_count = df_valid.count()

logger.info(f"Filas válidas: {valid_count}")
logger.info(f"Filas inválidas: {invalid_count}")

# ============================================================
# 6. Escribir quarantine
# ============================================================

if invalid_count > 0:
    (
        df_invalid
        .withColumn("quarantine_ts", F.current_timestamp())
        .write
        .mode("overwrite")
        .parquet(quarantine_path)
    )
    logger.info(f"Registros inválidos escritos en quarantine: {quarantine_path}")
else:
    logger.info("No se detectaron registros inválidos para quarantine.")

# ============================================================
# 7. Transformaciones curated
# ============================================================

df_curated = (
    df_valid
    .withColumn("event_date", F.to_date("timestamp_ts"))
    .withColumn("anio", F.year("timestamp_ts"))
    .withColumn("mes", F.month("timestamp_ts"))
    .withColumn("periodo_ym", F.date_format("timestamp_ts", "yyyy-MM"))
    .withColumn(
        "temp_critica_flag",
        F.when(
            (F.col("temperatura_num") > 30) | (F.upper(F.col("evento")) == "TEMP_CRITICA"),
            1
        ).otherwise(0)
    )
    .withColumn(
        "severidad_temperatura",
        F.when(F.col("temperatura_num") < 10, F.lit("BAJA"))
         .when((F.col("temperatura_num") >= 10) & (F.col("temperatura_num") <= 30), F.lit("NORMAL"))
         .otherwise(F.lit("ALTA"))
    )
    .select(
        "vehiculo",
        "timestamp",
        F.col("latitud_num").alias("latitud"),
        F.col("longitud_num").alias("longitud"),
        F.col("temperatura_num").alias("temperatura"),
        "evento",
        "timestamp_ts",
        "event_date",
        "anio",
        "mes",
        "periodo_ym",
        "temp_critica_flag",
        "severidad_temperatura"
    )
)

curated_count = df_curated.count()
logger.info(f"Filas finales a escribir en curated: {curated_count}")

# ============================================================
# 8. Escritura curated
# ============================================================

(
    df_curated
    .write
    .mode("overwrite")
    .partitionBy("periodo_ym")
    .parquet(output_path)
)

logger.info(f"Datos curated escritos en: {output_path}")
logger.info("Job sensores_curated finalizado correctamente")

job.commit()