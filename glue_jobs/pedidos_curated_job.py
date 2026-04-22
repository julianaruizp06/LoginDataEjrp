from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StructType
import sys

# ============================================================
# Job: pedidos_curated (CORREGIDO)
# - Lee tablas raw
# - Valida schema y calidad
# - Escribe válidos en curated
# - Escribe inválidos en quarantine con schema plano
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

# ============================================================
# 2. Validación de schema crítico
# ============================================================

required_columns_pedidos = ["id_pedido", "id_cliente", "id_producto", "fecha", "monto", "estado"]
required_columns_entregas = ["id_pedido", "hora_programada", "hora_real", "zona", "conductor", "vehiculo"]
required_columns_clientes = ["id_cliente", "nombre", "zona", "tipo_cliente"]
required_columns_catalogo = ["id_producto", "categoria", "precio", "tipo_entrega"]

def validate_required_columns(df, required_cols, df_name):
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise Exception(f"Schema inválido en {df_name}. Columnas faltantes: {missing}")

validate_required_columns(pedidos, required_columns_pedidos, "pedidos")
validate_required_columns(entregas, required_columns_entregas, "entregas")
validate_required_columns(clientes, required_columns_clientes, "clientes")
validate_required_columns(catalogo, required_columns_catalogo, "catalogo")

# ============================================================
# 3. Normalizar monto
# ============================================================

monto_field = next((f for f in pedidos.schema.fields if f.name == "monto"), None)

if monto_field is None:
    raise Exception("Schema inválido en pedidos. No existe la columna monto.")

if isinstance(monto_field.dataType, StructType):
    pedidos = pedidos.withColumn(
        "monto_num",
        F.coalesce(
            F.col("monto.double").cast("double"),
            F.regexp_replace(F.col("monto.string").cast("string"), ",", ".").cast("double")
        )
    )
else:
    pedidos = pedidos.withColumn(
        "monto_num",
        F.regexp_replace(F.col("monto").cast("string"), ",", ".").cast("double")
    )

# ============================================================
# 4. Normalización columnas
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
# 6. Validaciones
# ============================================================

valid_states = ["CREADO", "EN_DESPACHO", "ENTREGADO", "CANCELADO", "ANULADO"]

df_validated = (
    df
    .withColumn("fecha_pedido_ts", F.to_timestamp("fecha_pedido"))
    .withColumn("hora_programada_ts", F.to_timestamp("hora_programada"))
    .withColumn("hora_real_ts", F.to_timestamp("hora_real"))
    .withColumn(
        "validation_error",

        # Básicas
        F.when(F.col("id_pedido").isNull() | (F.trim(F.col("id_pedido")) == ""), F.lit("id_pedido vacío"))
        .when(F.col("id_cliente").isNull() | (F.trim(F.col("id_cliente")) == ""), F.lit("id_cliente vacío"))
        .when(F.col("id_producto").isNull() | (F.trim(F.col("id_producto")) == ""), F.lit("id_producto vacío"))

        # Monto
        .when(F.col("monto").isNull(), F.lit("monto nulo original"))
        .when(F.col("monto_num").isNull(), F.lit("monto inválido"))
        .when(F.col("monto_num") < 0, F.lit("monto negativo"))

        # Fechas
        .when(F.col("fecha_pedido_ts").isNull(), F.lit("fecha inválida"))

        # Estado
        .when(F.col("estado").isNull() | (~F.upper(F.col("estado")).isin(valid_states)), F.lit("estado inválido"))

        # Integridad referencial
        .when(F.col("nombre_cliente_raw").isNull(), F.lit("cliente no encontrado"))
        .when(F.col("categoria").isNull(), F.lit("producto no encontrado"))

        # Conductor / vehículo
        .when(
            (F.upper(F.col("estado")).isin("EN_DESPACHO", "ENTREGADO")) &
            (F.col("conductor").isNull() | (F.trim(F.col("conductor")) == "")),
            F.lit("conductor vacío en pedido operativo")
        )
        .when(
            (F.upper(F.col("estado")).isin("EN_DESPACHO", "ENTREGADO")) &
            (F.col("vehiculo").isNull() | (F.trim(F.col("vehiculo")) == "")),
            F.lit("vehiculo vacío en pedido operativo")
        )

        # Consistencia de estado
        .when(
            (F.upper(F.col("estado")) == "ENTREGADO") & F.col("hora_real_ts").isNull(),
            F.lit("pedido entregado sin hora_real")
        )
        .when(
            (F.upper(F.col("estado")).isin("ENTREGADO", "EN_DESPACHO")) &
            F.col("hora_programada_ts").isNull(),
            F.lit("pedido operativo sin hora_programada")
        )
    )
)

# ============================================================
# 6.1 Duplicados
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
    .join(duplicate_ids.withColumn("duplicate_flag", F.lit(1)), "id_pedido", "left")
    .withColumn(
        "validation_error",
        F.when(
            F.col("validation_error").isNull() & (F.col("duplicate_flag") == 1),
            F.lit("id_pedido duplicado")
        ).otherwise(F.col("validation_error"))
    )
)

# ============================================================
# 7. Split válidos / inválidos
# ============================================================

df_invalid = df_validated.filter(F.col("validation_error").isNotNull())
df_valid = df_validated.filter(F.col("validation_error").isNull())

invalid_count = df_invalid.count()
valid_count = df_valid.count()

logger.info(f"Filas válidas: {valid_count}")
logger.info(f"Filas inválidas: {invalid_count}")

# ============================================================
# 8. Quarantine con schema 100% plano
# ============================================================

if invalid_count > 0:
    # monto_raw plano y seguro
    if isinstance(monto_field.dataType, StructType):
        monto_raw_expr = F.to_json(F.col("monto"))
    else:
        monto_raw_expr = F.col("monto").cast("string")

    df_quarantine = (
        df_invalid
        .withColumn("quarantine_ts", F.current_timestamp())
        .withColumn("monto_raw", monto_raw_expr)
        .withColumn("fecha_pedido_raw", F.col("fecha_pedido").cast("string"))
        .withColumn("hora_programada_raw", F.col("hora_programada").cast("string"))
        .withColumn("hora_real_raw", F.col("hora_real").cast("string"))
        .select(
            F.col("id_pedido").cast("string").alias("id_pedido"),
            F.col("id_cliente").cast("string").alias("id_cliente"),
            F.col("id_producto").cast("string").alias("id_producto"),
            F.col("fecha_pedido_raw").alias("fecha_pedido"),
            F.col("monto_raw").alias("monto"),
            F.col("estado").cast("string").alias("estado"),
            F.col("monto_num").cast("double").alias("monto_num"),
            F.col("hora_programada_raw").alias("hora_programada"),
            F.col("hora_real_raw").alias("hora_real"),
            F.col("zona_entrega_raw").cast("string").alias("zona_entrega_raw"),
            F.col("conductor").cast("string").alias("conductor"),
            F.col("vehiculo").cast("string").alias("vehiculo"),
            F.col("nombre_cliente_raw").cast("string").alias("nombre_cliente_raw"),
            F.col("zona_cliente_raw").cast("string").alias("zona_cliente_raw"),
            F.col("tipo_cliente").cast("string").alias("tipo_cliente"),
            F.col("categoria").cast("string").alias("categoria"),
            F.col("precio").cast("double").alias("precio"),
            F.col("tipo_entrega").cast("string").alias("tipo_entrega"),
            F.col("fecha_pedido_ts").cast("timestamp").alias("fecha_pedido_ts"),
            F.col("hora_programada_ts").cast("timestamp").alias("hora_programada_ts"),
            F.col("hora_real_ts").cast("timestamp").alias("hora_real_ts"),
            F.col("validation_error").cast("string").alias("validation_error"),
            F.coalesce(F.col("duplicate_flag").cast("int"), F.lit(0)).alias("duplicate_flag"),
            F.col("quarantine_ts")
        )
    )

    logger.info(f"Schema quarantine: {df_quarantine.schema.simpleString()}")

    (
        df_quarantine
        .write
        .mode("overwrite")
        .parquet(quarantine_path)
    )

    logger.info(f"Registros inválidos escritos en quarantine: {quarantine_path}")
else:
    logger.info("No se detectaron registros inválidos para quarantine.")

# ============================================================
# 9. Curated
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

(
    df_curated
    .write
    .mode("overwrite")
    .partitionBy("periodo_ym")
    .parquet(output_path)
)

logger.info(f"Datos curated escritos en: {output_path}")
logger.info("Job finalizado correctamente")
job.commit()