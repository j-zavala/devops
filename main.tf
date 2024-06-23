terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.54"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source                    = "./vpc"
  app_name                  = var.app_name
  region                    = var.region
  vpc_cidr_block            = var.vpc_cidr_block
  public_subnet_cidr_block  = var.public_subnet_cidr_block
  private_subnet_cidr_block = var.private_subnet_cidr_block
}

resource "aws_security_group" "private_sg" {
  name        = "${var.app_name}-private-sg"
  description = "Allow HTTP from public subnet, all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.app_name}-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_allow_http_inbound_from_public_subnet" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.load_balancer_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP inbound traffic from public subnet"
}

resource "aws_vpc_security_group_egress_rule" "private_allow_all_outbound" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_instance" "private_instance" {
  count                       = 2
  ami                         = "ami-08a0d1e16fc3f61ea"
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnet_ids[count.index]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.private_ec2_instance_profile.name

  tags = {
    Name = "${var.app_name}-private-ec2-${count.index + 1}"
  }

  user_data = templatefile("private_ec2_nginx_setup.sh.tpl", {
    private_instance_name = "${var.app_name}-private-ec2-${count.index + 1}"
  })
}

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

# attaches the role to the policy
resource "aws_iam_role_policy_attachment" "private_ec2_policy_attachment" {
  role       = aws_iam_role.private_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# attaches our instance to the role
resource "aws_iam_instance_profile" "private_ec2_instance_profile" {
  name = "${var.app_name}-private-ec2-instance-profile"
  role = aws_iam_role.private_ec2_role.name
}

resource "aws_lb" "load_balancer" {
  name               = "${var.app_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = module.vpc.public_subnet_ids
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_http_inbound_from_internet" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP inbound traffic from internet"
}


resource "aws_vpc_security_group_egress_rule" "lb_allow_all_outbound_to_private_instances" {
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic to private instances"
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "${var.app_name}-load-balancer-sg"
  description = "Allows inbound HTTP from internet; then, outbound to private instances for request forwarding"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.app_name}-load-balancer-sg"
  }
}

# Target group
resource "aws_lb_target_group" "target_group" {
  name     = "${var.app_name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "private_instance_attachment" {
  count            = length(aws_instance.private_instance)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.private_instance[count.index].id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.load_balancer.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
