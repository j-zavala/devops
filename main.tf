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
  source = "./modules/vpc"

  app_name                  = var.app_name
  region                    = var.region
  vpc_cidr_block            = var.vpc_cidr_block
  public_subnet_cidr_block  = var.public_subnet_cidr_block
  private_subnet_cidr_block = var.private_subnet_cidr_block
  rds_subnet_cidr_block     = var.rds_subnet_cidr_block
}

# RDS
module "rds" {
  source = "./modules/rds"

  app_name               = var.app_name
  vpc_id                 = module.vpc.vpc_id
  rds_subnet_ids         = module.vpc.rds_subnet_ids
  rds_subnet_cidr_block  = var.rds_subnet_cidr_block
  private_instance_sg_id = module.ec2_instances.private_instance_sg_id
  db_username            = var.db_username
  db_password            = var.db_password
  db_name                = var.db_name
  bastion_sg_id          = module.ec2_instances.bastion_sg_id
}

# Load Balancer
module "load_balancer" {
  source = "./modules/load-balancer"

  app_name          = var.app_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_ids      = module.ec2_instances.instance_ids
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
  rds_subnet_id       = module.vpc.rds_subnet_ids[0]
  rds_sg_id           = module.rds.rds_sg_id
  user_data           = var.user_data
  load_balancer_sg_id = module.load_balancer.load_balancer_sg_id
}

# =========================================
# AWS Systems Manager Parameter Store 
# =========================================
resource "aws_ssm_parameter" "rds_endpoint_url" {
  name  = "/cwc/rds/endpoint"
  type  = "String"
  value = module.rds.rds_endpoint
}

