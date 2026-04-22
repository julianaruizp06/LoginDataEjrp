from datetime import datetime
import time
import boto3
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.exceptions import AirflowException

REGION = "us-east-1"
RAW_BUCKET = "ejrp-g01-raw-ejrp"
CURATED_BUCKET = "ejrp-g01-curated-ejrp"

GLUE_JOBS = {
    "pedidos": "pedidos-curated-job",
    "sensores": "sensores-curated-job",
    "dimensions": "dimensions-job",
}

ATHENA_DB = "logidata_curated"
ATHENA_OUTPUT = "s3://ejrp-g01-athena-results-ejrp/athena-results/"
ATHENA_WORKGROUP = "ejrp-g01-dev-wg"

GLUE_TIMEOUT_SECONDS = 60 * 60      # 1 hora
ATHENA_TIMEOUT_SECONDS = 20 * 60    # 20 minutos


def check_raw():
    s3 = boto3.client("s3", region_name=REGION)

    prefixes = [
        "raw/local/pedidos/",
        "raw/local/entregas/",
        "raw/local/clientes/",
        "raw/local/catalogo/",
        "raw/local/sensores/",
    ]

    for prefix in prefixes:
        response = s3.list_objects_v2(
            Bucket=RAW_BUCKET,
            Prefix=prefix,
            MaxKeys=1,
        )

        if "Contents" not in response or response.get("KeyCount", 0) == 0:
            raise AirflowException(f"Falta data en s3://{RAW_BUCKET}/{prefix}")

    print("RAW OK")


def run_glue(job_name, arguments=None):
    glue = boto3.client("glue", region_name=REGION)
    args = arguments or {}

    response = glue.start_job_run(JobName=job_name, Arguments=args)
    run_id = response["JobRunId"]

    print(f"Iniciado Glue job {job_name} con run_id={run_id}")
    print(f"Argumentos: {args}")

    start_time = time.time()

    while True:
        if time.time() - start_time > GLUE_TIMEOUT_SECONDS:
            raise AirflowException(f"Timeout esperando Glue job {job_name}")

        job_run = glue.get_job_run(JobName=job_name, RunId=run_id)["JobRun"]
        status = job_run["JobRunState"]
        print(f"{job_name} -> {status}")

        if status == "SUCCEEDED":
            return

        if status in {"FAILED", "STOPPED", "ERROR", "TIMEOUT"}:
            error_message = job_run.get("ErrorMessage", "Sin detalle")
            raise AirflowException(f"{job_name} falló: {error_message}")

        time.sleep(20)


def run_glue_pedidos():
    run_glue(
        GLUE_JOBS["pedidos"],
        {
            "--RAW_DB": "logidata_raw",
            "--CURATED_BUCKET": CURATED_BUCKET,
        },
    )


def run_glue_sensores():
    run_glue(
        GLUE_JOBS["sensores"],
        {
            "--RAW_DB": "logidata_raw",
            "--CURATED_BUCKET": CURATED_BUCKET,
        },
    )


def run_glue_dimensions():
    run_glue(
        GLUE_JOBS["dimensions"],
        {
            "--RAW_DB": "logidata_raw",
            "--CURATED_BUCKET": CURATED_BUCKET,
        },
    )


def run_athena_query(query: str):
    athena = boto3.client("athena", region_name=REGION)

    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": ATHENA_DB},
        ResultConfiguration={"OutputLocation": ATHENA_OUTPUT},
        WorkGroup=ATHENA_WORKGROUP,
    )

    query_id = response["QueryExecutionId"]
    print(f"Athena QueryExecutionId: {query_id}")
    print(query)

    start_time = time.time()

    while True:
        if time.time() - start_time > ATHENA_TIMEOUT_SECONDS:
            raise AirflowException(f"Timeout esperando Athena query {query_id}")

        execution = athena.get_query_execution(QueryExecutionId=query_id)["QueryExecution"]
        state = execution["Status"]["State"]
        print(f"Athena state: {state}")

        if state == "SUCCEEDED":
            return query_id

        if state in {"FAILED", "CANCELLED"}:
            reason = execution["Status"].get("StateChangeReason", "Sin detalle")
            raise AirflowException(f"Athena falló: {reason}")

        time.sleep(10)


def validation():
    # Validación mínima de existencia de datos
    run_athena_query("SELECT COUNT(*) FROM pedidos_curated")
    run_athena_query("SELECT COUNT(*) FROM sensores_curated")
    run_athena_query("SELECT COUNT(*) FROM dim_cliente")
    run_athena_query("SELECT COUNT(*) FROM dim_producto")
    run_athena_query("SELECT COUNT(*) FROM dim_vehiculo")


def demo():
    run_athena_query("""
    SELECT estado, COUNT(*) AS cantidad
    FROM pedidos_curated
    GROUP BY estado
    ORDER BY cantidad DESC
    """)

    run_athena_query("""
    SELECT severidad_temperatura, COUNT(*) AS cantidad
    FROM sensores_curated
    GROUP BY severidad_temperatura
    ORDER BY cantidad DESC
    """)


def notify_pipeline_status():
    print("Pipeline completado correctamente.")
    print("S3 raw -> Glue -> Athena OK")


default_args = {
    "owner": "logidata",
    "depends_on_past": False,
    "retries": 0,
}

with DAG(
    dag_id="logidata_pipeline_dag",
    start_date=datetime(2026, 4, 20),
    schedule=None,   # Cambia a "@daily" cuando quieras automatizarlo
    catchup=False,
    default_args=default_args,
    tags=["logidata", "airflow", "glue", "athena"],
) as dag:

    t1 = PythonOperator(
        task_id="check_raw_files",
        python_callable=check_raw,
    )

    t2 = PythonOperator(
        task_id="run_glue_pedidos_curated",
        python_callable=run_glue_pedidos,
    )

    t3 = PythonOperator(
        task_id="run_glue_sensores_curated",
        python_callable=run_glue_sensores,
    )

    t4 = PythonOperator(
        task_id="run_glue_dimensions",
        python_callable=run_glue_dimensions,
    )

    t5 = PythonOperator(
        task_id="run_athena_validation_queries",
        python_callable=validation,
    )

    t6 = PythonOperator(
        task_id="run_athena_demo_queries",
        python_callable=demo,
    )

    t7 = PythonOperator(
        task_id="notify_pipeline_status",
        python_callable=notify_pipeline_status,
    )

    t1 >> [t2, t3]
    [t2, t3] >> t4
    t4 >> t5 >> t6 >> t7