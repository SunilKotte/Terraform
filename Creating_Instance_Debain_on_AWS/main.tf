terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}


data "aws_ami" "debian_bookworm" {
  most_recent = true
  owners      = ["136693071363"] # Official Debian AMI owner ID

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"] # Adjust the pattern as needed (e.g., debian-11-amd64-*)
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "my_debian_instance" {
  ami           = data.aws_ami.debian_bookworm.id
  instance_type = "t2.micro"
  tags = {
    Name = "Learn01-AWS-Instance"
  }
}