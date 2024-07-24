resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.app_name}-rds-subnet-group"
  subnet_ids = var.rds_subnet_ids

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

resource "aws_vpc_security_group_ingress_rule" "rds_sg_ingress_rule_private" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = var.private_instance_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow incoming connections from EC2 instances"

  tags = {
    Name = "${var.app_name}-rds-sg-ingress-rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg_ingress_rule_bastion" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = var.bastion_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow incoming connections from EC2 Bastion Host"
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "${var.app_name}-rds-instance"
  allocated_storage      = 10
  instance_class         = "db.t3.micro"
  engine                 = "postgres"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "${var.app_name}-rds-instance"
  }
}
