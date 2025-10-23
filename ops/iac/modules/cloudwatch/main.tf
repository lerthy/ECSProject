# CloudWatch Module
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name}-dashboard"
  dashboard_body = var.dashboard_body
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.ecs_cpu_threshold
  alarm_description   = "ECS CPU > ${var.ecs_cpu_threshold}%"
  dimensions = {
    ClusterName = var.ecs_cluster_name
  }
  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]
  tags          = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "alb-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.0
  dimensions = {
    LoadBalancer = var.alb_name
  }
  alarm_description = "ALB latency too high"
  alarm_actions     = [var.sns_topic_arn]
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_ratio" {
  alarm_name          = "cloudfront-cache-hit-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }
  alarm_description = "CloudFront cache hit ratio too low"
  alarm_actions     = [var.sns_topic_arn]
  tags              = var.tags
}

# Custom application metrics alarms
resource "aws_cloudwatch_metric_alarm" "api_high_response_time" {
  alarm_name          = "api-high-response-time-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ResponseTime"
  namespace           = "ECommerce/API"
  period              = 300
  statistic           = "Average"
  threshold           = 2000 # 2 seconds
  alarm_description   = "API response time is too high"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_high_error_rate" {
  alarm_name          = "api-high-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestCount"
  namespace           = "ECommerce/API"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API error rate is too high"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  tags                = var.tags

  dimensions = {
    StatusCode = "5XX"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_low_request_count" {
  alarm_name          = "api-low-request-count-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "RequestCount"
  namespace           = "ECommerce/API"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "API request count is too low (possible outage)"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  tags                = var.tags
}
