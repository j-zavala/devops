variable "region" {
  type        = string
  description = "The region to deploy in"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block to use for the VPC"
}

variable "public_subnet_cidr_block" {
  type        = list(string)
  description = "The CIDR blocks to use for public subnets"
}

variable "private_subnet_cidr_block" {
  type        = list(string)
  description = "The CIDR blocks to use for private subnets"
}

variable "rds_subnet_cidr_block" {
  type        = list(string)
  description = "The CIDR blocks to use for RDS subnets"
}

variable "app_name" {
  type        = string
  description = "The name of the application"
}
