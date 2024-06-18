terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.54"
    }

    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
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

provider "tls" {}

provider "local" {}

provider "http" {}

data "http" "myip" {
  url = "https://api.ipify.org"
}

# output "bastion_host_ip" {
#   value = format("${aws_instance.bastion_host.public_ip}/32")
# }

# output "my_ip" {
  # value = format("${data.http.myip.response_body}/32")
# }

output "private_ip" {
  value = aws_instance.private_instance.private_ip
  # value = format("${aws_instance.private_instance.private_ip}/32")
}

# output "public_sg_id" {
#   value = aws_security_group.public_sg.id
# }

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

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "cwc-nat-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id = aws_subnet.public_subnet.id
  allocation_id = aws_eip.nat_eip.id

  tags = {
    Name = "cwc-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
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

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "cwc-private-route-table"
  }
}

resource "aws_route_table_association" "private_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "private_key" {
  filename = "${path.module}/cwc-key-pair.pem"
  content = tls_private_key.private_key.private_key_pem
  file_permission = "0600" # file is writable and readable only by the owner
}

resource "aws_key_pair" "key" {
  key_name = "cwc-key"
  public_key = tls_private_key.private_key.public_key_openssh
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

  user_data = templatefile("public_ec2_nginx_setup.sh.tpl", {
    private_ip = aws_instance.private_instance.private_ip
    # private_ip = format("${aws_instance.private_instance.private_ip}/32")
  })

  tags = {
    Name = "cwc-public-ec2"
  }

   depends_on = [aws_instance.private_instance]
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
  referenced_security_group_id  = aws_security_group.public_sg.id
  # cidr_ipv4 = "10.0.0.0/25"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description = "Allow HTTP inbound traffic from public subnet"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_inbound_from_bastion_host" {
  security_group_id = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id
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

  user_data = file("private_ec2_nginx_setup.sh.tpl")
}