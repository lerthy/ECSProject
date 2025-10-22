# RDS Module Outputs

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.primary.id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.primary.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.primary.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.primary.db_name
}

output "master_username" {
  description = "Master username for the database"
  value       = aws_db_instance.primary.username
  sensitive   = true
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.rds_credentials.name
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "read_replica_endpoint" {
  description = "Read replica endpoint (if created)"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].endpoint : null
}

output "read_replica_id" {
  description = "Read replica identifier (if created)"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].id : null
}

# Connection information for applications
output "connection_string" {
  description = "Database connection string template"
  value       = "postgresql://${aws_db_instance.primary.username}:${random_password.master_password.result}@${aws_db_instance.primary.endpoint}:${aws_db_instance.primary.port}/${aws_db_instance.primary.db_name}"
  sensitive   = true
}

output "connection_info" {
  description = "Database connection information"
  value = {
    host     = aws_db_instance.primary.address
    port     = aws_db_instance.primary.port
    database = aws_db_instance.primary.db_name
    username = aws_db_instance.primary.username
  }
}

# For monitoring and alerting
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for RDS logs"
  value       = aws_cloudwatch_log_group.postgresql.name
}
