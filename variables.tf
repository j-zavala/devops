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
  description = "The CIDR block to use for the public subnet"
}

variable "private_subnet_cidr_block" {
  type        = list(string)
  description = "The CIDR block to use for the private subnet"
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
