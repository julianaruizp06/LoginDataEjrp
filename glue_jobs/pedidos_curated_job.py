from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StructType
import sys

# ============================================================
# Job: pedidos_curated
# Lee tablas raw, valida schema, separa registros inválidos,
# escribe válidos en curated e inválidos en quarantine.
# ============================================================

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
quarantine_path = f"s3://{bucket}/quarantine/pedidos_curated/"

# ============================================================
# 1. Leer tablas raw
# ============================================================

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

logger.info(f"Columnas de pedidos detectadas: {pedidos.columns}")
logger.info(f"Columnas de entregas detectadas: {entregas.columns}")
logger.info(f"Columnas de clientes detectadas: {clientes.columns}")
logger.info(f"Columnas de catalogo detectadas: {catalogo.columns}")

# ============================================================
# 2. Validación de schema crítico
# Si falta una columna obligatoria, falla el job completo.
# ============================================================

required_columns_pedidos = ["id_pedido", "id_cliente", "id_producto", "fecha", "monto", "estado"]
required_columns_entregas = ["id_pedido", "hora_programada", "hora_real", "zona", "conductor", "vehiculo"]
required_columns_clientes = ["id_cliente", "nombre", "zona", "tipo_cliente"]
required_columns_catalogo = ["id_producto", "categoria", "precio", "tipo_entrega"]

def validate_required_columns(df, required_cols, df_name):
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise Exception(f"Schema inválido en {df_name}. Columnas faltantes: {missing}")

validate_required_columns(pedidos, required_columns_pedidos, "raw_local_pedidos")
validate_required_columns(entregas, required_columns_entregas, "raw_local_entregas")
validate_required_columns(clientes, required_columns_clientes, "raw_local_clientes")
validate_required_columns(catalogo, required_columns_catalogo, "raw_local_catalogo")

# ============================================================
# 3. Normalizar monto según el tipo real del schema
# Soporta monto simple o monto como struct.
# ============================================================

monto_field = next((f for f in pedidos.schema.fields if f.name == "monto"), None)

if monto_field is None:
    raise Exception("Schema inválido en raw_local_pedidos. No existe la columna monto.")

if isinstance(monto_field.dataType, StructType):
    logger.info("La columna 'monto' llegó como struct. Se normalizará usando subcampos.")
    pedidos = pedidos.withColumn(
        "monto_num",
        F.coalesce(
            F.col("monto.double").cast("double"),
            F.regexp_replace(F.col("monto.string").cast("string"), ",", ".").cast("double")
        )
    )
else:
    logger.info("La columna 'monto' llegó como tipo simple. Se normalizará con cast directo.")
    pedidos = pedidos.withColumn(
        "monto_num",
        F.regexp_replace(F.col("monto").cast("string"), ",", ".").cast("double")
    )

# ============================================================
# 4. Renombrar columnas para evitar ambigüedades
# ============================================================

pedidos = pedidos.withColumnRenamed("fecha", "fecha_pedido")

entregas = entregas.withColumnRenamed("zona", "zona_entrega_raw")

clientes = (
    clientes
    .withColumnRenamed("zona", "zona_cliente_raw")
    .withColumnRenamed("nombre", "nombre_cliente_raw")
)

# ============================================================
# 5. Join principal
# ============================================================

df = (
    pedidos
    .join(entregas, "id_pedido", "left")
    .join(clientes, "id_cliente", "left")
    .join(catalogo, "id_producto", "left")
)

raw_count = df.count()
logger.info(f"Filas después del join principal: {raw_count}")

# ============================================================
# 6. Parseo y validaciones de calidad fila a fila
# ============================================================

valid_states = ["CREADO", "EN_DESPACHO", "ENTREGADO", "CANCELADO", "ANULADO"]

df_validated = (
    df
    .withColumn("fecha_pedido_ts", F.to_timestamp("fecha_pedido"))
    .withColumn("hora_programada_ts", F.to_timestamp("hora_programada"))
    .withColumn("hora_real_ts", F.to_timestamp("hora_real"))
    .withColumn(
        "validation_error",
        F.when(F.col("id_pedido").isNull() | (F.trim(F.col("id_pedido")) == ""), F.lit("id_pedido vacío"))
        .when(F.col("id_cliente").isNull() | (F.trim(F.col("id_cliente")) == ""), F.lit("id_cliente vacío"))
        .when(F.col("id_producto").isNull() | (F.trim(F.col("id_producto")) == ""), F.lit("id_producto vacío"))
        .when(F.col("monto").isNull(), F.lit("monto nulo original"))
        .when(F.col("monto_num").isNull(), F.lit("monto inválido"))
        .when(F.col("monto_num") < 0, F.lit("monto negativo"))
        .when(F.col("fecha_pedido_ts").isNull(), F.lit("fecha_pedido inválida"))
        .when(F.col("estado").isNull() | (~F.upper(F.col("estado")).isin(valid_states)), F.lit("estado inválido"))
    )
)

# ============================================================
# 6.1 Detectar duplicados por id_pedido
# ============================================================

duplicate_ids = (
    df_validated
    .groupBy("id_pedido")
    .count()
    .filter(F.col("count") > 1)
    .select("id_pedido")
)

df_validated = (
    df_validated
    .join(
        duplicate_ids.withColumn("duplicate_flag", F.lit(1)),
        on="id_pedido",
        how="left"
    )
    .withColumn(
        "validation_error",
        F.when(
            F.col("validation_error").isNull() & (F.col("duplicate_flag") == 1),
            F.lit("id_pedido duplicado")
        ).otherwise(F.col("validation_error"))
    )
)

# ============================================================
# 7. Separar válidos e inválidos
# ============================================================

df_invalid = df_validated.filter(F.col("validation_error").isNotNull())
df_valid = df_validated.filter(F.col("validation_error").isNull())

invalid_count = df_invalid.count()
valid_count = df_valid.count()

logger.info(f"Filas válidas: {valid_count}")
logger.info(f"Filas inválidas: {invalid_count}")

# ============================================================
# 8. Escribir quarantine
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
# 9. Transformaciones Silver / curated
# ============================================================

df_curated = (
    df_valid
    .withColumn("fecha_pedido_date", F.to_date("fecha_pedido_ts"))
    .withColumn("anio_pedido", F.year("fecha_pedido_ts"))
    .withColumn("mes_pedido", F.month("fecha_pedido_ts"))
    .withColumn("periodo_ym", F.date_format("fecha_pedido_ts", "yyyy-MM"))
    .withColumn(
        "minutos_desviacion_entrega",
        (F.unix_timestamp("hora_real_ts") - F.unix_timestamp("hora_programada_ts")) / 60
    )
    .withColumn(
        "cancelado_flag",
        F.when(F.upper(F.col("estado")).isin("CANCELADO", "ANULADO"), 1).otherwise(0)
    )
    .withColumn(
        "entrega_a_tiempo_flag",
        F.when(
            (F.col("hora_real_ts").isNotNull()) &
            (F.col("hora_programada_ts").isNotNull()) &
            (F.col("hora_real_ts") <= F.col("hora_programada_ts")),
            1
        ).otherwise(0)
    )
    .select(
        "id_pedido",
        "id_cliente",
        "id_producto",
        "fecha_pedido_ts",
        F.col("fecha_pedido_date").alias("fecha_pedido"),
        "anio_pedido",
        "mes_pedido",
        "periodo_ym",
        F.col("monto_num").alias("monto"),
        "estado",
        "hora_programada_ts",
        "hora_real_ts",
        "minutos_desviacion_entrega",
        "entrega_a_tiempo_flag",
        "cancelado_flag",
        F.col("zona_entrega_raw").alias("zona_entrega"),
        "conductor",
        "vehiculo",
        F.col("nombre_cliente_raw").alias("nombre_cliente"),
        F.col("zona_cliente_raw").alias("zona_cliente"),
        "tipo_cliente",
        "categoria",
        F.col("precio").alias("precio_catalogo"),
        "tipo_entrega"
    )
)

curated_count = df_curated.count()
logger.info(f"Filas finales a escribir en curated: {curated_count}")

# ============================================================
# 10. Escritura curated
# ============================================================

(
    df_curated
    .write
    .mode("overwrite")
    .partitionBy("periodo_ym")
    .parquet(output_path)
)

logger.info(f"Datos curated escritos en: {output_path}")
logger.info("Job pedidos_curated finalizado correctamente")

job.commit()