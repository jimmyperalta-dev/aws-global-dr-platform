# terraform/environments/dr/variables.tf

# AWS Region
variable "aws_region" {
  description = "AWS region for DR infrastructure"
  type        = string
  default     = "us-west-2"
}

# Networking variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.20.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.21.0/24"]
}

variable "enable_nat_gateway" {
  description = "Should be true to provision NAT Gateway"
  type        = bool
  default     = true
}

# Compute variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG (DR typically smaller)"
  type        = number
  default     = 0
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG (DR typically smaller)"
  type        = number
  default     = 1
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "source_db_identifier" {
  description = "Identifier of the source database in primary region"
  type        = string
}
