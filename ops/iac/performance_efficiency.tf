# Performance Efficiency: CloudFront, S3, Athena

# CloudFront caching and performance settings are handled in the cloudfront module.
# S3 performance optimizations are handled in cost_optimization.tf to avoid duplicates

# Athena query example for optimized log analysis
resource "aws_athena_named_query" "ecs_logs" {
  name      = "ECSLogsQuery"
  database  = module.athena.athena_database_name
  query     = "SELECT * FROM ecs_logs WHERE status = 'ERROR' AND year = year(current_date) LIMIT 100;"
  workgroup = module.athena.athena_workgroup_name
}
