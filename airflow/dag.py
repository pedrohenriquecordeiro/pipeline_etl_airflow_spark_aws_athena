from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the test DAG
with DAG(
    's3_copy_dag',
    default_args=default_args,
    description='A simple DAG to copy files on S3 using BashOperator',
    schedule_interval=None,  # Run on demand
    start_date=datetime(2024, 11, 1),
    catchup=False,
) as dag:

    # Bash command to copy files from one S3 bucket to another
    s3_copy_task = BashOperator(
        task_id='copy_s3_file',
        bash_command='aws s3 cp s3://source-bucket-name/source-key s3://destination-bucket-name/destination-key',
    )

    s3_copy_task