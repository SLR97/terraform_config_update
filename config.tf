terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# VPC

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-VPC"
  }
}

# Pub Subnet
resource "aws_subnet" "mypubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "My-Pub-Sub"
  }
}

# Pvt Subnet
resource "aws_subnet" "mypvtsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "My-Pvt-Sub"
  }
}

# IGW 
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "My-IGW"
  }
}

# Pub Rt
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "Pub-RT"
  }
}

# Pub Rt Association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mypubsub.id
  route_table_id = aws_route_table.pubrt.id
}

# Pvt Rt
resource "aws_route_table" "pvtrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "Pvt-RT"
  }
}

# Pvt Rt Association
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.mypvtsub.id
  route_table_id = aws_route_table.pvtrt.id
}

# Pub SGP
resource "aws_security_group" "pubsgp" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Pub-SGP"
  }
}

# EIP
resource "aws_eip" "eip" {
  vpc      = true
}

# NAT GW
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.mypubsub.id

  tags = {
    Name = "NAT-GW"
  }
}

# Website
resource "aws_instance" "web" {
  ami           = "ami-0cca134ec43cf708f"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.pubsgp.id}"]
  subnet_id = aws_subnet.mypubsub.id
  tags = {
    Name = "Webserver"
  }
}
