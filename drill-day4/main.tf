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

# Get available AZ's
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2003 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "drill_030226" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "drill-vpc-030226"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "drill_030226" {
  vpc_id = aws_vpc.drill_030226.id

  tags = {
    Name = "drill-igw-030226"
  }

}

# Public Subnet
resource "aws_subnet" "public_subnet_030226" {
  vpc_id                  = aws_vpc.drill_030226.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "drill-public-subnet-030226"
  }
}

# Route Table
resource "aws_route_table" "public_route_table_030226" {
  vpc_id = aws_vpc.drill_030226.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.drill_030226.id
  }

  tags = {
    Name = "drill-public-route-table-030226"
  }
}

# Associate Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet_030226.id
  route_table_id = aws_route_table.public_route_table_030226.id
}

# Security Group - SSH
resource "aws_security_group" "ssh" {
  name        = "drill-ssh-sg-030226"
  description = "Allow SSH"
  vpc_id      = aws_vpc.drill_030226.id

  ingress {
    description = "SSH"
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

  tags = {
    Name = "drill-ssh-sg-030226"
  }
}

# Security Group - Web
resource "aws_security_group" "web" {
  name        = "drill-web-sg-030226"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.drill_030226.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "drill-web-sg-030226"
  }
}

# Key Pair (use existing or create)
resource "aws_key_pair" "drill_030226" {
  key_name   = "drill-key-030226"
  public_key = file("~/.ssh/id_rsa.pub")
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet_030226.id
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.web.id]
  key_name               = aws_key_pair.drill_030226.id

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Drill Day 4 - $(hostname)</h1>" > /usr/share/nginx/html/index.html      
              EOF

  tags = {
    Name = "drill-web-server"
  }
}