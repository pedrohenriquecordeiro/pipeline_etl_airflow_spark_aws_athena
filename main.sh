
# provisiona o servidor airflow
terraform -chdir="./airflow" init &&
terraform -chdir="./airflow" apply --auto-aprove &&

# move os arquivos de codigo para o s3
# move codigo da dag
aws s3 mv airflow/dag.py s3://projeto-0003-phcj/code/dags &&
# move codigo do job spark
aws s3 mv pyspark/job-spark.py s3://projeto-0003-phcj/code/spark