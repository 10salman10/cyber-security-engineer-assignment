provider "aws" {
  region = "ap-southeast-1"
}

# Define VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" 

  tags = {
    Name = "MainVPC"
  }
}

# Subnet for VPN server
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"  
  availability_zone = "ap-southeast-1a"   

  tags = {
    Name = "PublicSubnet"
  }
}

# Subnet for HTTP server
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"  
  availability_zone = "ap-southeast-1a"   

  tags = {
    Name = "PrivateSubnet"
  }
}

# VPN server ec2
resource "aws_instance" "vpn_server" {
  ami           = "ami-0eb4694aa6f249c52"  
  instance_type = "t2.micro"                
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.vpn_server_sg.id]  
  #User data to install WireGuard
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y wireguard
    
  EOF

  tags = {
    Name = "VPN_Server"
  }
}

# WEb server Ec2
resource "aws_instance" "http_server" {
  ami           = "ami-0eb4694aa6f249c52"  
  instance_type = "t2.micro"                
  subnet_id     = aws_subnet.private.id

  

  tags = {
    Name = "HTTP_Server_VIO"
  }
}

# SG for VPN server
resource "aws_security_group" "vpn_server_sg" {
  vpc_id = aws_vpc.main.id

  
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["171.76.81.27/32"]  # allowing from my IP
  }

  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG for HTTPS server
resource "aws_security_group" "http_server_sg" {
  vpc_id = aws_vpc.main.id

 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Allowing traffic from VPN server subnet
  }

 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpn_server_public_ip" {
  value = aws_instance.vpn_server.public_ip
}
