# terraform/environments/dr/main.tf

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dr"
      Project     = "aws-global-dr-platform"
      ManagedBy   = "terraform"
    }
  }
}

# Networking module
module "networking" {
  source = "../../modules/networking"

  environment             = "dr"
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  database_subnet_cidrs  = var.database_subnet_cidrs
  enable_nat_gateway     = var.enable_nat_gateway
}

# Compute module
module "compute" {
  source = "../../modules/compute"

  environment             = "dr"
  aws_region             = var.aws_region
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_subnet_ids     = module.networking.private_subnet_ids
  alb_security_group_id  = module.networking.alb_security_group_id
  ec2_security_group_id  = module.networking.ec2_security_group_id
  instance_type          = var.instance_type
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
}

# Database module (read replica)
module "database" {
  source = "../../modules/database"

  environment             = "dr"
  is_primary             = false
  db_subnet_group_name   = module.networking.db_subnet_group_name
  rds_security_group_id  = module.networking.rds_security_group_id
  db_instance_class      = var.db_instance_class
  source_db_identifier   = var.source_db_identifier
}

# Storage module
module "storage" {
  source = "../../modules/storage"

  environment                    = "dr"
  enable_cross_region_replication = false
}
