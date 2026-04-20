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

CRAWLER_NAME = "crawler-curated-ejrp"
ATHENA_DB = "logidata_curated"
ATHENA_OUTPUT = "s3://ejrp-g01-athena-results-ejrp/"
ATHENA_WORKGROUP = "ejrp-g01-dev-wg"


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
        response = s3.list_objects_v2(Bucket=RAW_BUCKET, Prefix=prefix, MaxKeys=1)
        if response.get("KeyCount", 0) == 0:
            raise AirflowException(f"Falta data en s3://{RAW_BUCKET}/{prefix}")

    print("RAW OK")

def run_glue(job_name, arguments=None):
    glue = boto3.client("glue", region_name=REGION)
    args = arguments or {}

    response = glue.start_job_run(JobName=job_name, Arguments=args)
    run_id = response["JobRunId"]

    print(f"Iniciado Glue job {job_name} con run_id={run_id}")
    print(f"Argumentos: {args}")

    while True:
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
            "--force_refresh": "true",
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


def run_crawler():
    glue = boto3.client("glue", region_name=REGION)

    try:
        glue.start_crawler(Name=CRAWLER_NAME)
        print(f"Crawler {CRAWLER_NAME} iniciado")
    except glue.exceptions.CrawlerRunningException:
        print(f"Crawler {CRAWLER_NAME} ya estaba corriendo")

    while True:
        crawler = glue.get_crawler(Name=CRAWLER_NAME)["Crawler"]
        state = crawler["State"]
        print(f"Crawler state: {state}")

        if state == "READY":
            last_crawl = crawler.get("LastCrawl", {})
            last_status = last_crawl.get("Status", "UNKNOWN")
            print(f"Last crawl status: {last_status}")

            if last_status == "SUCCEEDED":
                return

            raise AirflowException(f"Crawler terminó sin éxito: {last_status}")

        time.sleep(15)


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

    while True:
        execution = athena.get_query_execution(QueryExecutionId=query_id)["QueryExecution"]
        state = execution["Status"]["State"]
        print(f"Athena state: {state}")

        if state == "SUCCEEDED":
            return

        if state in {"FAILED", "CANCELLED"}:
            reason = execution["Status"].get("StateChangeReason", "Sin detalle")
            raise AirflowException(f"Athena falló: {reason}")

        time.sleep(10)


def validation():
    run_athena_query("SELECT COUNT(*) FROM pedidos_curated")
    run_athena_query("SELECT COUNT(*) FROM sensores_curated")


def demo():
    run_athena_query("""
    SELECT estado, COUNT(*) AS cantidad
    FROM pedidos_curated
    GROUP BY estado
    ORDER BY cantidad DESC
    """)


def notify_pipeline_status():
    print("Pipeline completado correctamente.")
    print("S3 raw -> Glue -> Curated -> Crawler -> Athena OK")


with DAG(
    dag_id="logidata_pipeline_dag",
    start_date=datetime(2026, 4, 20),
    schedule=None,
    catchup=False,
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
        task_id="run_curated_crawler",
        python_callable=run_crawler,
    )

    t6 = PythonOperator(
        task_id="run_athena_validation_queries",
        python_callable=validation,
    )

    t7 = PythonOperator(
        task_id="run_athena_demo_queries",
        python_callable=demo,
    )

    t8 = PythonOperator(
        task_id="notify_pipeline_status",
        python_callable=notify_pipeline_status,
    )

    t1 >> [t2, t3]
    [t2, t3] >> t4
    t4 >> t5 >> t6 >> t7 >> t8