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
