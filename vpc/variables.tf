variable "region" {
  type        = string
  description = "The region to deploy in"
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block to use for the VPC"
  default     = "10.0.0.0/24"
}

variable "public_subnet_cidr_block" {
  type        = list(string)
  description = "The CIDR block to use for the public subnet"
  default     = ["10.0.0.0/26", "10.0.0.64/26"]
}

variable "private_subnet_cidr_block" {
  type        = list(string)
  description = "The CIDR block to use for the private subnet"
  default     = ["10.0.0.128/26", "10.0.0.192/26"]
}

variable "app_name" {
  type        = string
  description = "The name of the application"
  default     = "cwc"
}