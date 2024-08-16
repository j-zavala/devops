output "alb_dns_name" {
  value = module.load_balancer.load_balancer_dns_name
}

output "rds_endpoint_ssm_parameter" {
  value       = aws_ssm_parameter.rds_endpoint_url.name
  description = "The SSM Parameter Store name for the RDS endpoint"
}

output "repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}
