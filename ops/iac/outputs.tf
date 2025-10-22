output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}
output "frontend_bucket_arn" {
  value = module.s3.frontend_bucket_arn
}
output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}
output "sns_topic_arn" {
  value = module.sns.sns_topic_arn
}
output "athena_database_name" {
  value = module.athena.athena_database_name
}

# =====================
# RDS Database Outputs
# =====================

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.rds_port
}

output "database_name" {
  description = "Name of the database"
  value       = module.rds.database_name
}

output "database_secrets_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.rds.secrets_manager_secret_arn
}

output "database_connection_info" {
  description = "Database connection information for applications"
  value       = module.rds.connection_info
  sensitive   = true
}

# =====================
# RDS Standby Database Outputs
# =====================

output "rds_standby_endpoint" {
  description = "RDS standby instance endpoint"
  value       = module.rds_standby.rds_endpoint
}

output "rds_standby_port" {
  description = "RDS standby instance port"
  value       = module.rds_standby.rds_port
}

output "database_standby_secrets_arn" {
  description = "ARN of the Secrets Manager secret containing standby database credentials"
  value       = module.rds_standby.secrets_manager_secret_arn
}

output "database_standby_connection_info" {
  description = "Standby database connection information for applications"
  value       = module.rds_standby.connection_info
  sensitive   = true
}
