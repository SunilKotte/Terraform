terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50"
    }
  }
  required_version = ">= 1.4.0"
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

resource "aws_security_group" "sg_ssh" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_https" {
  ingress {
    cidr_blocks = ["192.168.0.0/16"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }
}

resource "aws_instance" "sg-instance" {
  ami                    = data.aws_ami.debian_bookworm.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_ssh.id, aws_security_group.sg_https.id]
  tags = {
    Name = "SG-VM"
  }
}