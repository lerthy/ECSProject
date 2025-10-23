output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.alerts[0].arn : data.aws_sns_topic.alerts[0].arn
}
