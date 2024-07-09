output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = aws_instance.private_instance[*].id
}

output "private_sg_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "iam_role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.private_ec2_role.name
}

output "instance_profile_name" {
  description = "Name of the created IAM instance profile"
  value       = aws_iam_instance_profile.private_ec2_instance_profile.name
}
