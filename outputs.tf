output "alb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.relational_db.endpoint
}
