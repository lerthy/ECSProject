# CloudWatch Alarms for ALB & CloudFront
# Added for observability completion

variable "alb_latency_threshold" {
  description = "Threshold for ALB latency alarm (seconds)"
  type        = number
  default     = 1
}

variable "alb_5xx_threshold" {
  description = "Threshold for ALB 5xx error count alarm"
  type        = number
  default     = 5
}

variable "cloudfront_cache_hit_ratio_threshold" {
  description = "Threshold for CloudFront cache hit ratio alarm (%)"
  type        = number
  default     = 80
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.alb_name}-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.alb_latency_threshold
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
  alarm_description   = "ALB latency exceeds threshold"
  alarm_actions       = [module.sns.sns_topic_arn]
  ok_actions          = [module.sns.sns_topic_arn]
  tags                = var.tags
  depends_on          = [module.alb]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.alb_name}-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
  alarm_description   = "ALB 5xx errors exceed threshold"
  alarm_actions       = [module.sns.sns_topic_arn]
  ok_actions          = [module.sns.sns_topic_arn]
  tags                = var.tags
  depends_on          = [module.alb]
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_hit_ratio" {
  alarm_name          = "cloudfront-cache-hit-ratio-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = 60
  statistic           = "Average"
  threshold           = var.cloudfront_cache_hit_ratio_threshold
  dimensions = {
    DistributionId = module.cloudfront.cloudfront_distribution_id
    Region         = "Global"
  }
  alarm_description   = "CloudFront cache hit ratio below threshold"
  alarm_actions       = [module.sns.sns_topic_arn]
  ok_actions          = [module.sns.sns_topic_arn]
  tags                = var.tags
  depends_on          = [module.cloudfront]
}

output "alb_latency_alarm_arn" {
  description = "ARN of the ALB latency alarm"
  value       = aws_cloudwatch_metric_alarm.alb_latency.arn
}

output "alb_5xx_errors_alarm_arn" {
  description = "ARN of the ALB 5xx errors alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
}

output "cloudfront_cache_hit_ratio_alarm_arn" {
  description = "ARN of the CloudFront cache hit ratio alarm"
  value       = aws_cloudwatch_metric_alarm.cloudfront_cache_hit_ratio.arn
}
