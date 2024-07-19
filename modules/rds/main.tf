resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.app_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.app_name}-rds-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.app_name}-rds-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg_ingress_rule" {
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.private_instance_sg_id
  description                  = "Allow incoming connections from EC2 instances"

  tags = {
    Name = "${var.app_name}-rds-sg-ingress-rule"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_sg_egress_rule" {
  security_group_id = aws_security_group.rds_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  description       = "Allow outgoing connections to any destination"

  tags = {
    Name = "${var.app_name}-rds-sg-egress-rule"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "${var.app_name}-rds-instance"
  allocated_storage      = 10
  instance_class         = "db.t3.micro"
  engine                 = "postgres"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "${var.app_name}-rds-instance"
  }
}
