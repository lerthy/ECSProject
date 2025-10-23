# Lambda for Slack notifications (optional, if slack_webhook is set)
resource "aws_lambda_function" "slack_notifier" {
  count            = var.slack_webhook != "" ? 1 : 0
  filename         = "${path.module}/slack_notifier.zip"
  function_name    = "sns-slack-notifier-${var.name}"
  role             = aws_iam_role.lambda_slack_notifier[0].arn
  handler          = "index.handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/slack_notifier.zip")
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook
    }
  }
  tags = var.tags
}

resource "aws_iam_role" "lambda_slack_notifier" {
  count = var.slack_webhook != "" ? 1 : 0
  name  = "lambda-sns-slack-notifier-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count      = var.slack_webhook != "" ? 1 : 0
  role       = aws_iam_role.lambda_slack_notifier[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "allow_sns" {
  count         = var.slack_webhook != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "slack" {
  count      = var.slack_webhook != "" ? 1 : 0
  topic_arn  = aws_sns_topic.alerts.arn
  protocol   = "lambda"
  endpoint   = aws_lambda_function.slack_notifier[0].arn
  depends_on = [aws_lambda_permission.allow_sns]
}
# SNS Module
resource "aws_sns_topic" "alerts" {
  name = var.name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count      = var.sns_alert_email != "" ? 1 : 0
  topic_arn  = aws_sns_topic.alerts.arn
  protocol   = "email"
  endpoint   = var.sns_alert_email
  depends_on = [aws_sns_topic.alerts]
}
