output "rds_endpoint" {
  value       = aws_db_instance.rds_instance.endpoint
  description = "The connection endpoint for the RDS instance"
}
output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
