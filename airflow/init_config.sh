#!/bin/bash

# INSTALL DOCKER
sudo apt-get update -y
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo groupadd docker
sudo gpasswd -a $USER docker
sudo service docker restart
sudo docker context use default

# INSTALL APACHE AIRFLOW
mkdir airflow
cd airflow
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.5.1/docker-compose.yaml'
sed -i "s/AIRFLOW__CORE__LOAD_EXAMPLES: 'true'/AIRFLOW__CORE__LOAD_EXAMPLES: 'false'/g" docker-compose.yaml
mkdir -p ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)" > .env
AIRFLOW_UID=50000
sudo docker compose up airflow-init
sudo docker compose up -d

# ENVIRONMENT VARIABLES
sudo apt install jq -y
aws_access_key_emr=$(jq -r '.aws_access_key' credentials_file_aws/emr_user_accessKeys.json)
aws_secret_key_emr=$(jq -r '.aws_secret_key' credentials_file_aws/emr_user_accessKeys.json)

# SETUP AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
AWS_PROFILE='USER_AWS_EMR'
aws configure set aws_access_key_id aws_access_key_emr
aws configure set aws_secret_key aws_access_key_emr
aws configure set default_region 'us-east-1'
aws configure set output 'json'