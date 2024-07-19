# =========================================
# Terraform Provider Configuration
# =========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# =========================================
# Module Configurations
# =========================================
# VPC
module "vpc" {
  source                    = "./modules/vpc"
  app_name                  = var.app_name
  region                    = var.region
  vpc_cidr_block            = var.vpc_cidr_block
  public_subnet_cidr_block  = var.public_subnet_cidr_block
  private_subnet_cidr_block = var.private_subnet_cidr_block
}

# RDS
module "rds" {
  source = "./modules/rds"

  app_name               = var.app_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  private_instance_sg_id = module.ec2_instances.private_instance_sg_id
  db_username            = var.db_username
  db_password            = var.db_password
}

# Load Balancer
module "load_balancer" {
  source = "./modules/load-balancer"

  app_name            = var.app_name
  vpc_id              = module.vpc.vpc_id
  load_balancer_sg_id = aws_security_group.load_balancer_sg.id
  public_subnet_ids   = module.vpc.public_subnet_ids
  instance_ids        = module.ec2_instances.instance_ids
}

# EC2 Instances 
module "ec2_instances" {
  source = "./modules/ec2"

  app_name            = var.app_name
  instance_count      = var.instance_count
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  private_subnet_ids  = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  load_balancer_sg_id = aws_security_group.load_balancer_sg.id
  rds_sg_id           = module.rds.rds_sg_id
  user_data           = var.user_data
}

# =========================================
# Security Groups
# =========================================

# Load Balancer Security Group
resource "aws_security_group" "load_balancer_sg" {
  name        = "${var.app_name}-load-balancer-sg"
  description = "Allows inbound HTTP from internet; then, outbound to private instances for request forwarding"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.app_name}-load-balancer-sg"
  }
}

# =========================================
# Security Group Rules
# =========================================

# Load Balancer Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "lb_allow_http_inbound_from_internet" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP inbound traffic from internet"
}


resource "aws_vpc_security_group_egress_rule" "lb_allow_all_outbound_to_private_instances" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic to private instances"
}
