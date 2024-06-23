# =========================================
# Data Sources
# =========================================

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# =========================================
# VPC
# =========================================
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# =========================================
# Subnets
# =========================================

# Public Subnets
resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-public-subnet-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-private-subnet-${count.index + 1}"
  }
}

# =========================================
# Internet Gateway
# =========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# =========================================
# Public Route Tables and Associations
# =========================================

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.app_name}-public-route-table"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public_table_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# =========================================
# NAT Gateways and EIPs
# =========================================

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${var.app_name}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gw" {
  count         = 2
  subnet_id     = aws_subnet.public_subnet[count.index].id
  allocation_id = aws_eip.nat_eip[count.index].id

  tags = {
    Name = "${var.app_name}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# =========================================
# Private Route Tables and Associations
# =========================================

# Private Route Tables
resource "aws_route_table" "private_route_table" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "${var.app_name}-private-route-table-${count.index + 1}"
  }
}

# Private Route Table Associations
resource "aws_route_table_association" "private_table_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}
