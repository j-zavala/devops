# =========================================
# Load Balancer
# =========================================
resource "aws_lb" "load_balancer" {
  name               = "${var.app_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = var.public_subnet_ids
}

# =========================================
# Security Groups
# =========================================

# Load Balancer Security Group
resource "aws_security_group" "load_balancer_sg" {
  name        = "${var.app_name}-load-balancer-sg"
  description = "Allows inbound HTTP from internet; then, outbound to private instances for request forwarding"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-load-balancer-sg"
  }
}

# =========================================
# Security Group Rules
# =========================================

# Load Balancer Security Group Rules
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


# ALB Target groups
resource "aws_lb_target_group" "target_group" {
  name     = "${var.app_name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/hello"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach Instances to Target Group
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = var.instance_ids[count.index]
  port             = 80
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
