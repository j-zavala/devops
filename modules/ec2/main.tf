# =========================================
# EC2 Instances
# =========================================
resource "aws_instance" "private_instance" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  // allows us to use SSM to connect to the instance
  iam_instance_profile = aws_iam_instance_profile.private_ec2_instance_profile.name

  tags = {
    Name = "${var.app_name}-private-ec2-${count.index + 1}"
  }

  user_data = file(var.user_data)
}

resource "aws_instance" "bastion_host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.rds_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.private_ec2_instance_profile.name

  tags = {
    Name = "${var.app_name}-bastion-host"
  }
}

# =========================================
# Security Groups
# =========================================

# Private Security Group
resource "aws_security_group" "private_sg" {
  name        = "${var.app_name}-private-sg"
  description = "Allow HTTP from public subnet, all outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-private-sg"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.app_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-bastion-sg"
  }
}

# =========================================
# Security Group Rules
# =========================================

# Private Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "private_allow_http_inbound_from_lb" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = var.load_balancer_sg_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP inbound traffic from load balancer"
}

resource "aws_vpc_security_group_egress_rule" "allow_ec2_to_rds_private" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = var.rds_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow outbound traffic from EC2 to RDS instance"

  tags = {
    Name = "${var.app_name}-allow-ec2-to-rds-egress-rule"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_ec2_to_rds_bastion" {
  security_group_id            = aws_security_group.bastion_sg.id
  referenced_security_group_id = var.rds_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow outbound traffic from EC2 Bastion Host to RDS instance"
}

resource "aws_vpc_security_group_egress_rule" "allow_bastion_https_outbound" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow outbound HTTPS traffic for SSM and other AWS services"
}

resource "aws_vpc_security_group_egress_rule" "private_allow_all_outbound" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

# =========================================
# IAM Role and Instance Profile
# =========================================
resource "aws_iam_role" "private_ec2_role" {
  name = "${var.app_name}-private-ec2-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# IAM policy for SSM Parameter Store access
resource "aws_iam_policy" "ssm_parameter_access" {
  name        = "${var.app_name}-ssm-parameter-access"
  path        = "/"
  description = "IAM policy for accessing SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/cwc/*"
      },
    ]
  })
}

# Attach the SSM Parameter Store access policy to the role
resource "aws_iam_role_policy_attachment" "ssm_parameter_access_attachment" {
  role       = aws_iam_role.private_ec2_role.name
  policy_arn = aws_iam_policy.ssm_parameter_access.arn
}

# Attach the AmazonEC2ContainerRegistryReadOnly policy to the role
resource "aws_iam_role_policy_attachment" "ecr_readonly_policy_attachment" {
  role       = aws_iam_role.private_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.private_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the AmazonEC2RoleforSSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm_role_policy_attachment" {
  role       = aws_iam_role.private_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Attach instance to the role
resource "aws_iam_instance_profile" "private_ec2_instance_profile" {
  name = "${var.app_name}-private-ec2-instance-profile"
  role = aws_iam_role.private_ec2_role.name
}
