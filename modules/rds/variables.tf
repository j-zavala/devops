variable "app_name" {}
variable "vpc_id" {}
variable "rds_subnet_cidr_block" {}
variable "private_instance_sg_id" {}
variable "db_username" {}
variable "db_password" {}
variable "db_name" {}
variable "bastion_sg_id" {}
variable "rds_subnet_ids" {
  type        = list(string)
  description = "The IDs of the RDS subnets"
}
