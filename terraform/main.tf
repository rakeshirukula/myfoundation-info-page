terraform {
  backend "s3" {
    bucket = "myenvrakesh"
    key    = "terraform.tfstate"
    region = "us-east-1"  # Change to your AWS region
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "The AWS region to create the VPC in"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The S3 bucket name to store kubeconfig"
  type        = string
  default     = "myenvrakesh"
}

# VPC Creation
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "mygithub-vpc"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Modify for your region
  map_public_ip_on_launch = true  # Ensures EC2 gets a public IP

  tags = {
    Name = "mygithub-public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mygithub-igw"
  }
}

# Create a Route Table and Associate it with the Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "mygithub-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# EC2 Instance in Public Subnet with Public IP
resource "aws_instance" "master" {
  ami             = "ami-01816d07b1128cd2d"  # Amazon Linux 2 AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  associate_public_ip_address = true  # Assigns a public IP to the EC2 instance

  user_data = file("userdata_master.sh")

  tags = {
    Name = "master-node"
  }
}

# Null resource to upload kubeconfig file to S3
resource "null_resource" "upload_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
    if [ -f /root/.kube/config ]; then
      aws s3 cp /root/.kube/config s3://${var.s3_bucket_name}/kubeconfig
    else
      echo "Kubeconfig file does not exist."
    fi
    EOT
  }

  depends_on = [aws_instance.master]
}

output "master_public_ip" {
  value = aws_instance.master.public_ip
}
