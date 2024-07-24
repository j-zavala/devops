
variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 2
}

variable "ami_id" {
  type        = string
  description = "AMI ID to use for the EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs to launch the instances in"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the instances and security group will be created"
}


variable "user_data" {
  type        = string
  description = "User data script for EC2 instances"
}

variable "rds_sg_id" {
  description = "The ID of the RDS security group"
  type        = string
}

variable "rds_subnet_id" {
  type        = string
  description = "The ID of the RDS subnet where the bastion host will be placed"
}

variable "load_balancer_sg_id" {
  type        = string
  description = "ID of the load balancer security group"
}
