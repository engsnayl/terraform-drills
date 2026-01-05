terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Data source - latest Amazon Linux 2 AMI
data "aws_ami" "amazon_Linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group
resource "aws_security_group" "web" {
  name        = "drill-day1-sg"
  description = "Day 1 drill security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "drill-day1-sg"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_Linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
                #!/bin/bash
                yum install -y httpd
                systemctl start httpd
                echo "<h1>Day 1 Terraform Drill</h1>" > /var/www/html/index.html
                EOF

  tags = {
    Name = "drill-day1-instance"
  }
}

# Outputs

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
