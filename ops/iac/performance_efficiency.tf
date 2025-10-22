# Performance Efficiency: CloudFront, S3, Athena

# CloudFront caching and performance settings are handled in the cloudfront module.
# S3 performance optimizations: Enable transfer acceleration and intelligent tiering
resource "aws_s3_bucket_accelerate_configuration" "frontend" {
  bucket = module.s3.frontend_bucket_name
  status = "Enabled"
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "frontend" {
  bucket = module.s3.frontend_bucket_name
  name   = "it"
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# Athena query example for optimized log analysis
resource "aws_athena_named_query" "ecs_logs" {
  name      = "ECSLogsQuery"
  database  = module.athena.athena_database_name
  query     = "SELECT * FROM ecs_logs WHERE status = 'ERROR' AND year = year(current_date) LIMIT 100;"
  workgroup = module.athena.athena_workgroup_name
}
