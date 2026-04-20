from airflow import DAG
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow.providers.amazon.aws.operators.athena import AthenaOperator
from airflow.providers.amazon.aws.sensors.glue import GlueJobSensor
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from datetime import timedelta

# --- Configuración de Argumentos ---
DEFAULT_ARGS = {
    'owner': 'Erika Ruiz',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='logidata_spark_pipeline_v1',
    default_args=DEFAULT_ARGS,
    schedule_interval=None,  # Se lanza manualmente o por trigger de S3
    catchup=False,
    tags=['DataOps', 'Spark', 'Glue'],
) as dag:

    # 1. Verificar presencia de archivos en RAW
    check_raw_files = S3ListOperator(
        task_id='check_raw_files',
        bucket='ejrp-g01-raw-ejrp',
        prefix='raw/',
        aws_conn_id='aws_default'
    )

    # 2. Ejecutar Jobs de Spark (En paralelo los hechos)
    run_glue_pedidos = GlueJobOperator(
        task_id='run_glue_pedidos_curated',
        job_name='pedidos-curated-job',
        script_args={'--RAW_DB': 'logidata_raw', '--CURATED_BUCKET': 'ejrp-g01-curated-ejrp'},
        aws_conn_id='aws_default'
    )

    run_glue_sensores = GlueJobOperator(
        task_id='run_glue_sensores_curated',
        job_name='sensores-curated-job',
        script_args={'--RAW_DB': 'logidata_raw', '--CURATED_BUCKET': 'ejrp-g01-curated-ejrp'},
        aws_conn_id='aws_default'
    )

    # 3. Ejecutar Dimensiones 
    run_glue_dimensions = GlueJobOperator(
        task_id='run_glue_dimensions',
        job_name='dimensions-job',
        script_args={'--RAW_DB': 'logidata_raw', '--CURATED_BUCKET': 'ejrp-g01-curated-ejrp'},
        aws_conn_id='aws_default'
    )

    # 4. Actualizar Catálogo con el Crawler
    # Nota: Usamos PythonOperator para disparar el crawler via Boto3 si no hay operador directo
    def trigger_crawler():
        import boto3
        client = boto3.client('glue')
        client.start_crawler(Name='crawler-curated-ejrp')

    run_curated_crawler = PythonOperator(
        task_id='run_curated_crawler',
        python_callable=trigger_crawler
    )

    # 5. Queries de Validación en Athena
    run_athena_validation = AthenaOperator(
        task_id='run_athena_validation_queries',
        query='SELECT COUNT(*) FROM logidata_curated.vw_analisis_pedidos_spark',
        database='logidata_curated',
        output_location='s3://ejrp-g01-athena-results-ejrp/athena-results-into-spark/',
        aws_conn_id='aws_default'
    )

    # --- Definición de Dependencias (Flujo) ---
    check_raw_files >> [run_glue_pedidos, run_glue_sensores]
    [run_glue_pedidos, run_glue_sensores] >> run_glue_dimensions
    run_glue_dimensions >> run_curated_crawler
    run_curated_crawler >> run_athena_validation