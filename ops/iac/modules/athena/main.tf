# Athena Module

# Data sources for dynamic S3 paths
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_athena_database" "logs" {
  name   = var.database_name
  bucket = var.s3_bucket
}

resource "aws_athena_workgroup" "logs" {
  name = var.workgroup_name
  configuration {
    result_configuration {
      output_location = var.output_location
    }
  }
  state         = "ENABLED"
  force_destroy = true
  tags          = var.tags
}

# ALB Access Logs Table
resource "aws_athena_named_query" "create_alb_logs_table" {
  name        = "create-alb-logs-table-${var.environment}"
  workgroup   = aws_athena_workgroup.logs.name
  database    = aws_athena_database.logs.name
  description = "Creates ALB access logs table with partition projection"

  query = <<-EOT
    CREATE EXTERNAL TABLE IF NOT EXISTS ${aws_athena_database.logs.name}.alb_logs (
      type string,
      time string,
      elb string,
      client_ip string,
      client_port int,
      target_ip string,
      target_port int,
      request_processing_time double,
      target_processing_time double,
      response_processing_time double,
      elb_status_code int,
      target_status_code string,
      received_bytes bigint,
      sent_bytes bigint,
      request_verb string,
      request_url string,
      request_proto string,
      user_agent string,
      ssl_cipher string,
      ssl_protocol string,
      target_group_arn string,
      trace_id string,
      domain_name string,
      chosen_cert_arn string,
      matched_rule_priority string,
      request_creation_time string,
      actions_executed string,
      redirect_url string,
      lambda_error_reason string,
      target_port_list string,
      target_status_code_list string,
      classification string,
      classification_reason string
    )
    PARTITIONED BY (
       year string,
       month string,
       day string
    )
    STORED AS INPUTFORMAT 
      'org.apache.hadoop.mapred.TextInputFormat' 
    OUTPUTFORMAT 
      'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    LOCATION '${var.alb_logs_s3_location}'
    TBLPROPERTIES (
      'projection.enabled'='true',
      'projection.year.type'='integer',
      'projection.year.range'='2020,2030',
      'projection.year.digits'='4',
      'projection.month.type'='integer',
      'projection.month.range'='1,12',
      'projection.month.digits'='2',
      'projection.day.type'='integer',
      'projection.day.range'='1,31',
      'projection.day.digits'='2',
      'storage.location.template'='${var.alb_logs_s3_location}$${year}/$${month}/$${day}/'
    )
  EOT
}

# Sample Queries for ALB Analysis
resource "aws_athena_named_query" "alb_top_ips" {
  name        = "alb-top-client-ips-${var.environment}"
  workgroup   = aws_athena_workgroup.logs.name
  database    = aws_athena_database.logs.name
  description = "Find top client IPs by request count"

  query = <<-EOT
    SELECT 
        client_ip,
        COUNT(*) as request_count,
        COUNT(DISTINCT request_url) as unique_urls,
        AVG(response_processing_time) as avg_response_time
    FROM ${aws_athena_database.logs.name}.alb_logs
    WHERE year = '$${year}' AND month = '$${month}' AND day = '$${day}'
    GROUP BY client_ip
    ORDER BY request_count DESC
    LIMIT 20
  EOT
}

resource "aws_athena_named_query" "alb_error_analysis" {
  name        = "alb-error-analysis-${var.environment}"
  workgroup   = aws_athena_workgroup.logs.name
  database    = aws_athena_database.logs.name
  description = "Analyze 4xx and 5xx errors"

  query = <<-EOT
    SELECT 
        time,
        client_ip,
        request_verb,
        request_url,
        elb_status_code,
        target_status_code,
        user_agent,
        response_processing_time
    FROM ${aws_athena_database.logs.name}.alb_logs
    WHERE year = '$${year}' AND month = '$${month}' AND day = '$${day}'
      AND (elb_status_code >= 400 OR target_status_code LIKE '4%' OR target_status_code LIKE '5%')
    ORDER BY time DESC
    LIMIT 100
  EOT
}
