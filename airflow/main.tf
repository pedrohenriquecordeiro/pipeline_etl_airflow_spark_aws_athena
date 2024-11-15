terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73.0"
    }
  }

  required_version = ">= 1.2.0"
}

# Define the path to the credentials file
variable "credentials_file" {
  default = "credentials_file_aws/terraform_user_acessKeys.json"
}

# Read and parse the JSON config file
locals {
  credentials_data = jsondecode(file(var.credentials_file))
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
      instance_interruption_behavior = "terminate" # Behavior when interrupted: "terminate", "stop", or "hibernate"
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

  user_data = file("init.sh")
  
}
