provider "aws" {
  region = var.aws_region
}
#create vpc
resource "aws_vpc" "notezipper_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name="notezipper-vpc"
  }
}
#create subnet
resource "aws_subnet" "notezipper_subnet" {
  vpc_id = aws_vpc.notezipper_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = {
    Name="notezipper-subnet"
  }
}
#create internet gateway
resource "aws_internet_gateway" "notezipper-igw" {
  vpc_id = aws_vpc.notezipper_vpc.id
  tags = {
    Name="notezipper-igw"
  }
}
# create route table
resource "aws_route_table" "notezipper_tr" {
  vpc_id = aws_vpc.notezipper_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.notezipper-igw.id
  }
tags = {
    Name="notezipper-rt"
  }
}
# create route table association
resource "aws_route_table_association" "public" {
   subnet_id = aws_subnet.notezipper_subnet.id
   route_table_id = aws_route_table.notezipper_tr.id
}
#create security group
resource "aws_security_group" "notezipper-sg" {
  name = "notezipper-sg"
  description = "security group for the notezipper"
  vpc_id = aws_vpc.notezipper_vpc.id

# Allow incoming HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict to your IP
  }

  # Allow incoming traffic for Node.js app
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming traffic for React app
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "notezipper-sg"
  }

  
}

# create ec2 instance
resource "aws_instance" "notezipper_server" {
  ami=var.ami_id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.notezipper_subnet.id
  vpc_security_group_ids = [aws_security_group.notezipper-sg.id]
  key_name = var.key_pair_name
  user_data = templatefile("userdata.sh", {
    mongodburi = var.mongodb_uri
    jwtsecret = var.jwt_secret
  })
  tags = {
    Name = "notezipper-server"
  }
}