terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    http = {
      source = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

provider "http" {}

data "http" "myip" {
  url = "https://api.ipify.org"
}

output "bastion_host_ip" {
  value = format("${aws_instance.bastion_host.public_ip}/32")
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "cwc-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/25" # 128 ip addresses
  availability_zone  = "us-east-1a" # optional

  tags = {
    Name = "cwc-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.128/25" # 128 ip addresses
  availability_zone  = "us-east-1a" # optional

  tags = {
    Name = "cwc-private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cwc-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "cwc-public-route-table"
  }
}

resource "aws_route_table_association" "public_table_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cwc-private-route-table"
  }
}

resource "aws_route_table_association" "private_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_key_pair" "key" {
  key_name = "cwc-key"
  public_key = file("./cwc-key-pair.pem.pub")
}

resource "aws_security_group" "public_sg" {
  name = "cwc-public-sg" # This is the actual name of the security group in AWS
  description = "Allow SSH and HTTP inbound traffic, and all outbound traffic"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cwc-public-sg" # This is a tag named "Name" with the value "public_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_ssh_inbound_rule" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4 = format("${data.http.myip.response_body}/32")
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description = "Allow SSH inbound traffic from personal ip"
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_http_inbound_rule" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description = "Allow HTTP inbound traffic from the Internet"
}

resource "aws_vpc_security_group_egress_rule" "public_allow_all_outbound_rule" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol       = "-1" # This means all protocols
  description = "Allow all outbound traffic"
}

resource "aws_instance" "public_instance" {
  ami                         = "ami-08a0d1e16fc3f61ea"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.public_sg.id]

  tags = {
    Name = "cwc-public-ec2"
  }
}
####################### PRIVATE SG & EC2 #######################

resource "aws_security_group" "private_sg" {
  name = "cwc-private-sg" # This is the actual name of the security group in AWS
  description = "Allow HTTP from public subnet, SSH from bastion host, all outbound traffic"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cwc-private-sg" # This is a tag named "Name" with the value "private_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_inbound_from_public_subnet" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4 = "10.0.0.0/25"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description = "Allow HTTP inbound traffic from public subnet"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_inbound_from_bastion_host" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4 = format("${aws_instance.bastion_host.public_ip}/32")
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description = "Allow SSH inbound traffic from bastion host"
}

resource "aws_vpc_security_group_egress_rule" "private_allow_all_outbound_rule" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol       = "-1" # This means all protocols
  description = "Allow all outbound traffic"
}

resource "aws_instance" "private_instance" {
  ami                         = "ami-08a0d1e16fc3f61ea"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.private_sg.id]

  tags = {
    Name = "cwc-private-ec2"
  }
}

####################### BASTION SG & EC2 #######################

resource "aws_security_group" "bastion_sg" {
  name = "cwc-bastion-sg" # This is the actual name of the security group in AWS
  description = "Allow SSH from personal IP address, allow all outbound traffic"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cwc-bastion-sg" # This is a tag named "Name" with the value "bastion_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_allow_ssh_inbound_rule" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4 = format("${data.http.myip.response_body}/32")
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description = "Allow SSH inbound traffic from personal ip"
}

resource "aws_vpc_security_group_egress_rule" "bastion_allow_all_outbound_rule" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol       = "-1" # This means all protocols
  description = "Allow all outbound traffic"
}

resource "aws_instance" "bastion_host" {
  ami                         = "ami-08a0d1e16fc3f61ea"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "cwc-bastion-host-ec2"
  }
}