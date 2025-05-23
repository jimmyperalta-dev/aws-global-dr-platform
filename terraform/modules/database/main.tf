# terraform/modules/database/main.tf

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# AWS Secrets Manager secret for database password
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix             = "${var.environment}-db-password-"
  description             = "Database password for ${var.environment} environment"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.environment}-db-password"
    Environment = var.environment
    Project     = "aws-global-dr-platform"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# RDS instance for primary region
resource "aws_db_instance" "main" {
  count = var.is_primary ? 1 : 0

  identifier = "${var.environment}-database"

  # Database configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database settings
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # High availability
  multi_az = true

  # Enable automated backups for cross-region replica
  copy_tags_to_snapshot = true
  deletion_protection   = false

  # Performance Insights
  performance_insights_enabled = true

  # Skip final snapshot for demo purposes
  skip_final_snapshot = true

  tags = {
    Name        = "${var.environment}-database"
    Environment = var.environment
    Project     = "aws-global-dr-platform"
  }
}

# RDS read replica for disaster recovery region
resource "aws_db_instance" "replica" {
  count = var.is_primary ? 0 : 1

  identifier = "${var.environment}-database-replica"

  # Replica configuration
  replicate_source_db = var.source_db_identifier

  # Instance configuration
  instance_class = var.db_instance_class

  # Network configuration
  vpc_security_group_ids = [var.rds_security_group_id]

  # Performance Insights
  performance_insights_enabled = true

  # Skip final snapshot for demo purposes
  skip_final_snapshot = true

  tags = {
    Name        = "${var.environment}-database-replica"
    Environment = var.environment
    Project     = "aws-global-dr-platform"
  }
}
