provider "aws" {
  region = var.region
}

variable "region" {
  description = "The AWS region to create the VPC in"
  type        = string
  default     = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.1.0/16"

  tags = {
    Name = "mygithub-vpc"
  }
}
