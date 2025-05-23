# terraform/modules/database/outputs.tf

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = var.is_primary ? (length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].id : null) : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].id : null)
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = var.is_primary ? (length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].arn : null) : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].arn : null)
}

output "db_instance_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = var.is_primary ? (length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].endpoint : null) : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].endpoint : null)
}

output "db_instance_hosted_zone_id" {
  description = "Hosted zone ID of the RDS instance"
  value       = var.is_primary ? (length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].hosted_zone_id : null) : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].hosted_zone_id : null)
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = var.is_primary ? (length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].port : null) : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].port : null)
}

output "db_name" {
  description = "Name of the database"
  value       = var.db_name
}

output "db_username" {
  description = "Username for the database"
  value       = var.db_username
  sensitive   = true
}

output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "Name of the Secrets Manager secret containing the database password"
  value       = aws_secretsmanager_secret.db_password.name
}
