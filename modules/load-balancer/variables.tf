variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "load_balancer_sg_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "instance_ids" {
  type        = list(string)
  description = "List of EC2 instance IDs to attach to the target group"
}
