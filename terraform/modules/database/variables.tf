# terraform/modules/database/variables.tf

variable "environment" {
  description = "Environment name (primary or dr)"
  type        = string
  validation {
    condition     = can(regex("^(primary|dr)$", var.environment))
    error_message = "Environment must be either 'primary' or 'dr'."
  }
}

variable "is_primary" {
  description = "Whether this is the primary database (true) or replica (false)"
  type        = bool
}

variable "db_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
}

variable "rds_security_group_id" {
  description = "ID of the RDS security group"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition = can(regex("^db\\.(t3|t2)\\.(micro|small|medium|large|xlarge|2xlarge)$", var.db_instance_class))
    error_message = "DB instance class must be a valid RDS instance type."
  }
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "DB allocated storage must be between 20 and 1000 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 100
  validation {
    condition     = var.db_max_allocated_storage >= 20 && var.db_max_allocated_storage <= 2000
    error_message = "DB max allocated storage must be between 20 and 2000 GB."
  }
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "drplatform"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters."
  }
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_username))
    error_message = "Database username must start with a letter and contain only alphanumeric characters."
  }
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in format HH:MM-HH:MM."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
  validation {
    condition = can(regex("^(sun|mon|tue|wed|thu|fri|sat):[0-2][0-9]:[0-5][0-9]-(sun|mon|tue|wed|thu|fri|sat):[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "Maintenance window must be in format ddd:HH:MM-ddd:HH:MM."
  }
}

variable "source_db_identifier" {
  description = "Identifier of the source database for replica (only used in DR region)"
  type        = string
  default     = ""
}
