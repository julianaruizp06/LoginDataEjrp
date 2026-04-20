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
output_path = f"s3://{args['CURATED_BUCKET']}/curated/sensores_curated/"

df_sensores = glueContext.create_dynamic_frame.from_catalog(
    database=raw_db, 
    table_name="raw_local_sensores"
).toDF()

row_count_raw = df_sensores.count()
print(f"Registros encontrados en RAW: {row_count_raw}")


df_curated = df_sensores \
    .withColumn("timestamp_ts", F.to_timestamp("timestamp")) \
    .withColumn("event_date", F.to_date("timestamp_ts")) \
    .withColumn("anio", F.year("timestamp_ts")) \
    .withColumn("mes", F.month("timestamp_ts")) \
    .withColumn("periodo_ym", F.date_format("timestamp_ts", "yyyy-MM")) \
    .withColumn(
        "temp_critica_flag",
        F.when(F.col("temperatura") > 30, 1).otherwise(0)
    ) \
    .withColumn(
        "severidad_temperatura",
        F.when(F.col("temperatura") < 10, "BAJA")
         .when((F.col("temperatura") >= 10) & (F.col("temperatura") <= 30), "NORMAL")
         .otherwise("ALTA")
    )

df_curated.printSchema()


df_curated.write \
    .mode("overwrite") \
    .partitionBy("periodo_ym") \
    .parquet(output_path)


job.commit()