import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, ["JOB_NAME", "RAW_DB", "CURATED_BUCKET"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

raw_db = args["RAW_DB"]
curated_bucket = args["CURATED_BUCKET"]
base_output_path = f"s3://{curated_bucket}/curated"

# --- 1. Cargar Tablas ---
df_clientes = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_clientes").toDF()
df_pedidos = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_pedidos").toDF()
df_catalogo = glueContext.create_dynamic_frame.from_catalog(database=raw_db, table_name="raw_local_catalogo").toDF()

# --- 2. DIM_CLIENTE ---
dim_cliente = df_clientes.select(
    "id_cliente", 
    F.col("nombre").alias("nombre_cliente"), 
    "tipo_cliente", 
    "zona"
).distinct()

# --- 3. DIM_PRODUCTO  ---
dim_producto = df_catalogo.select(
    "id_producto", 
    F.col("tipo_entrega").alias("nombre_producto"), 
    "categoria", 
    "precio"
).distinct()

# --- 4. DIM_VEHICULO  ---
# Si 'vehiculo' no existe, usamos 'id_pedido' temporalmente para no romper el flujo
col_vehiculo = "vehiculo" if "vehiculo" in df_pedidos.columns else "id_pedido"
col_conductor = "conductor" if "conductor" in df_pedidos.columns else "estado"

dim_vehiculo = df_pedidos.select(
    F.col(col_vehiculo).alias("id_vehiculo"),
    F.col(col_conductor).alias("conductor")
).distinct()

# --- 5. DIM_FECHA ---
dim_fecha = df_pedidos.select("fecha").distinct() \
    .withColumn("fecha_dt", F.to_date("fecha")) \
    .withColumn("anio", F.year("fecha_dt")) \
    .withColumn("mes", F.month("fecha_dt")) \
    .withColumn("periodo_ym", F.date_format("fecha_dt", "yyyy-MM")) \
    .select("fecha", "fecha_dt", "anio", "mes", "periodo_ym")

# --- 6. Escritura ---
dimensiones = {
    "dim_cliente": dim_cliente,
    "dim_producto": dim_producto,
    "dim_vehiculo": dim_vehiculo,
    "dim_fecha": dim_fecha
}

for nombre_dim, df in dimensiones.items():
    df.write.mode("overwrite").parquet(f"{base_output_path}/{nombre_dim}/")

job.commit()
