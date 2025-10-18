# SNS Module
resource "aws_sns_topic" "alerts" {
  name = var.name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_sns_topic_subscription" "slack" {
  count     = var.slack_webhook != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook
}
