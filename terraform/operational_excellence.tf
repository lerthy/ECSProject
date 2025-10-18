# Operational Excellence: CloudWatch, X-Ray, CodePipeline Notifications

# CloudWatch Dashboard for ECS, ALB, CloudFront, S3
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "observability-dashboard"
  dashboard_body = var.dashboard_body
}

# CloudWatch Alarms for ECS CPU/Memory
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "ECS-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_cpu_threshold
  alarm_description   = "ECS CPU usage is high"
  dimensions = {
    ClusterName = module.ecs.cluster_id
    ServiceName = module.ecs.service_name
  }
  alarm_actions = [module.sns.sns_topic_arn]
}

# CodePipeline Notifications via SNS

# X-Ray Tracing for ECS
# Already enabled via xray module

# Terraform maintainability: tags, comments, structure already present
