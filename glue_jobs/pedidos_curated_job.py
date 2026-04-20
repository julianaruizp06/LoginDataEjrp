from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
import sys

# Configuración inicial
args = getResolvedOptions(sys.argv, ["JOB_NAME", "RAW_DB", "CURATED_BUCKET"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

logger = glueContext.get_logger()
logger.info("Iniciando job pedidos_curated optimizado")

raw_db = args["RAW_DB"]
bucket = args["CURATED_BUCKET"]
output_path = f"s3://{bucket}/curated/pedidos_curated/"

# --- 1. Leer tablas ---
# Leemos y renombramos inmediatamente usando .selectExpr o withColumnRenamed
pedidos = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_pedidos").toDF()
pedidos = pedidos.withColumnRenamed("fecha", "fecha_pedido") # ASEGÚRATE QUE ESTA LÍNEA ESTÉ SOLA

entregas = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_entregas").toDF()
entregas = entregas.withColumnRenamed("zona", "zona_entrega_raw")

clientes = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_clientes").toDF()
clientes = clientes.withColumnRenamed("zona", "zona_cliente_raw") \
                   .withColumnRenamed("nombre", "nombre_cliente_raw")

catalogo = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_catalogo").toDF()

# Agrega esta línea para que en los logs de CloudWatch podamos ver si el cambio ocurrió
print("Columnas de pedidos detectadas:", pedidos.columns)

# RENOMBRAMOS 'zona' en entregas para evitar la ambigüedad
entregas = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_entregas").toDF() \
    .withColumnRenamed("zona", "zona_entrega_raw")

# RENOMBRAMOS 'zona' en clientes para evitar la ambigüedad
clientes = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_clientes").toDF() \
    .withColumnRenamed("zona", "zona_cliente_raw") \
    .withColumnRenamed("nombre", "nombre_cliente_raw")

catalogo = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_catalogo").toDF()

# --- 2. Join principal ---
df = pedidos \
    .join(entregas, "id_pedido", "left") \
    .join(clientes, "id_cliente", "left") \
    .join(catalogo, "id_producto", "left")

# --- 3. Transformaciones ---
df_curated = df \
    .withColumn("fecha_pedido_ts", F.to_timestamp("fecha_pedido")) \
    .withColumn("fecha_pedido_date", F.to_date("fecha_pedido_ts")) \
    .withColumn("anio_pedido", F.year("fecha_pedido_ts")) \
    .withColumn("mes_pedido", F.month("fecha_pedido_ts")) \
    .withColumn("periodo_ym", F.date_format("fecha_pedido_ts", "yyyy-MM")) \
    .withColumn("hora_programada_ts", F.to_timestamp("hora_programada")) \
    .withColumn("hora_real_ts", F.to_timestamp("hora_real")) \
    .withColumn(
        "minutos_desviacion_entrega", 
        (F.unix_timestamp("hora_real_ts") - F.unix_timestamp("hora_programada_ts")) / 60
    ) \
    .withColumn(
        "cancelado_flag",
        F.when(F.upper(F.col("estado")).isin("CANCELADO", "ANULADO"), 1).otherwise(0)
    ) \
    .withColumn(
        "entrega_a_tiempo_flag",
        F.when(
            (F.col("hora_real_ts").isNotNull()) & (F.col("hora_real_ts") <= F.col("hora_programada_ts")), 
            1
        ).otherwise(0)
    ) \
    .select(
        "id_pedido", "id_cliente", "id_producto", "fecha_pedido_ts", 
        F.col("fecha_pedido_date").alias("fecha_pedido"),
        "anio_pedido", "mes_pedido", "periodo_ym", "monto", "estado",
        "hora_programada_ts", "hora_real_ts", "minutos_desviacion_entrega",
        "entrega_a_tiempo_flag", "cancelado_flag",
        F.col("zona_entrega_raw").alias("zona_entrega"), # Usamos el nuevo nombre único
        "conductor", "vehiculo",
        F.col("nombre_cliente_raw").alias("nombre_cliente"), 
        F.col("zona_cliente_raw").alias("zona_cliente"), # Agregamos la zona del cliente también
        "tipo_cliente", "categoria", 
        F.col("precio").alias("precio_catalogo"), "tipo_entrega"
    )

# --- 4. Escritura ---
df_curated.write \
    .mode("overwrite") \
    .partitionBy("periodo_ym") \
    .parquet(output_path)

job.commit()