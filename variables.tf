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

variable "user_data" {
  type        = string
  description = "User data script for EC2 instances"
  default     = "private_ec2_docker_setup.sh.tpl"
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 2
}

variable "ami_id" {
  type        = string
  description = "AMI ID to use for the EC2 instances"
  default     = "ami-06c68f701d8090592"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "db_username" {
  type        = string
  description = "Username for the RDS instance"
}

variable "db_password" {
  type        = string
  description = "Password for the RDS instance"
}

variable "db_name" {
  type        = string
  description = "The name of the database to create when the RDS instance is created"
}
