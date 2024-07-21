variable "app_name" {}
variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "private_instance_sg_id" {}
variable "db_username" {}
variable "db_password" {}
variable "db_name" {}
