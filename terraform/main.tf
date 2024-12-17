provider "aws" {
  region = var.region
}

variable "region" {
  description = "The AWS region to create the VPC in"
  type        = string
  default     = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "mygithub-vpc"
  }
}


resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "main-subnet"
  }
}

resource "aws_instance" "master" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id

  user_data = file("userdata_master.sh")

  tags = {
    Name = "master-node"
  }
}

resource "aws_instance" "agent" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id

  user_data = file("userdata_agent.sh")

  tags = {
    Name = "agent-node"
  }
}

resource "aws_s3_bucket" "kubeconfig_bucket" {
  bucket = "kubeconfigfile"
}

resource "null_resource" "upload_kubeconfig" {
  provisioner "local-exec" {
    command = "aws s3 cp /root/.kube/config s3://${aws_s3_bucket.kubeconfig_bucket.id}/kubeconfig"
  }

  depends_on = [aws_instance.master, aws_instance.agent]
}

output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "agent_public_ip" {
  value = aws_instance.agent.public_ip
}
