# SNS Module
resource "aws_sns_topic" "alerts" {
  name = var.name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.sns_alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_alert_email
  depends_on = [aws_sns_topic.alerts]
}
