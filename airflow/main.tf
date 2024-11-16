terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73.0"
    }
  }

  required_version = ">= 1.2.0"
}


variable "variables" {
  default = "credentials/env.json"
}

# Define the path to the credentials file
variable "terraform_credentials_file" {
  default = "credentials/terraform_user_acessKeys.json"
}

# Read and parse the JSON config file
locals {
  credentials_data = jsondecode(file(var.terraform_credentials_file))
  variables = jsondecode(file(var.variables))
}

# Configure the AWS provider using the parsed values
provider "aws" {
  region     = "us-east-1"
  access_key = local.credentials_data["aws_access_key"]
  secret_key = local.credentials_data["aws_secret_key"]
}

resource "aws_instance" "app_server" {

  ami = "ami-0866a3c8686eaeeba" # Ubuntu
  instance_type = "t2.large"
  vpc_security_group_ids = [ "sg-0393818ae4528e01f" ]
  iam_instance_profile = "RoleS3FullAcess"
  key_name = "key_pair_ec2_aws"
  
  # Define instance as a Spot Instance with market options
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
      instance_interruption_behavior = "terminate" 
      # Behavior when interrupted: "terminate", "stop", or "hibernate"
    }
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp3" # General Purpose SSD
    encrypted = true
    tags = {
      Name = "airflow"
    }
  }

  tags = {
    Name = "airflow-instance"
  }

  provisioner "file" {
    source      = "docker-compose.yaml"  # Path to the local file
    destination = "./docker-compose.yaml"  # Path on the EC2 instance
  }

  provisioner "remote-exec" {
    inline = [
      "ls -l ./docker-compose.yaml",  # Verify the file was uploaded
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("/Users/pedrojesus/key_pair_ec2_aws.pem")  # Path to your private key
  }

  user_data = <<-EOF
    #!/bin/bash

    #    # INSTALL DOCKER
    #    sudo apt-get update -y
    #    sudo apt-get install ca-certificates curl -y
    #    sudo install -m 0755 -d /etc/apt/keyrings
    #    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    #    sudo chmod a+r /etc/apt/keyrings/docker.asc
    #    echo \
    #      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    #      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    #      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    #    sudo apt-get update -y
    #    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    #    sudo groupadd docker
    #    sudo gpasswd -a $USER docker
    #    sudo service docker restart
    #    sudo docker context use default
    #
    #    # INSTALL APACHE AIRFLOW
    #    mkdir airflow
    #    mv docker-compose airflow
    #    cd airflow
    #    mkdir -p ./dags ./logs ./plugins
    #    echo -e "AIRFLOW_UID=$(id -u)" > .env
    #    AIRFLOW_UID=50000
    #    sudo docker compose up airflow-init
    #    sudo docker compose up -d

    # Set environment variable permanently in the user's shell profile
    echo 'export GIT_SYNC_REPO=${local.variables["GIT_SYNC_REPO"]}' >> ~/.bashrc
    source ~/.bashrc

  EOF
  
}
