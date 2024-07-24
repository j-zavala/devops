output "load_balancer_dns_name" {
  value = aws_lb.load_balancer.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "load_balancer_sg_id" {
  value = aws_security_group.load_balancer_sg.id
}
