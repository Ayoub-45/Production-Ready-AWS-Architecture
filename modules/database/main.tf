resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-db-subnets"
  description = "Private database subnets for ${var.project_name}"
  subnet_ids  = var.db_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

# No egress rules on purpose: the database never initiates outbound connections.
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "PostgreSQL access from the application tier only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.app_security_group_id

  from_port   = var.db_port
  to_port     = var.db_port
  ip_protocol = "tcp"

  description = "PostgreSQL from the application instances"
}

# Refuse unencrypted client connections.
resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.project_name}-pg-"
  family      = "postgres${var.engine_major_version}"
  description = "PostgreSQL parameters for ${var.project_name}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-pg"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-db"

  engine         = "postgres"
  engine_version = var.engine_major_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username
  port     = var.db_port

  # RDS generates the password, stores it in Secrets Manager and rotates it.
  # It never appears in Terraform code or state.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  multi_az = false

  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true

  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-db-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  # The snapshot name is fixed when the instance is created, so every
  # create/destroy cycle gets a unique name and never collides with an old snapshot.
  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }

  tags = {
    Name = "${var.project_name}-db"
  }
}
