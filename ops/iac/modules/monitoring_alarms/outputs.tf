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
