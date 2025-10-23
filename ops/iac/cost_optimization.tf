# Cost Optimization Configuration
# Added per best practices for operational excellence

# S3 Intelligent Tiering for cost optimization
resource "aws_s3_bucket_intelligent_tiering_configuration" "frontend" {
  bucket = module.s3.frontend_bucket_name
  name   = "EntireBucket"
  
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# S3 Transfer Acceleration for performance and cost optimization
resource "aws_s3_bucket_accelerate_configuration" "frontend" {
  bucket = module.s3.frontend_bucket_name
  status = "Enabled"
}

# CloudWatch Cost Anomaly Detection
resource "aws_ce_anomaly_detector" "cost_anomaly" {
  name = "cost-anomaly-detector"
  
  specification = jsonencode({
    threshold = 100.0
    type      = "ANOMALY_DETECTION"
  })
  
  tags = var.tags
}

# Cost and Usage Report
resource "aws_cur_report_definition" "cost_report" {
  report_name                = "cost-and-usage-report"
  time_unit                 = "DAILY"
  format                    = "textORcsv"
  compression              = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                = module.s3.alb_logs_bucket_name
  s3_prefix                = "cost-reports/"
  s3_region               = data.aws_region.current.name
  
  additional_artifacts = [
    "REDSHIFT",
    "QUICKSIGHT"
  ]
}

# Data source for current region
data "aws_region" "current" {}