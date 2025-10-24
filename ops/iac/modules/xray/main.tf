# X-Ray Module
resource "aws_xray_group" "default" {
  filter_expression = "service(\"${var.name}\")"
  group_name        = var.name
  insights_configuration {
    insights_enabled = true
  }
  tags = var.tags
}

# X-Ray Sampling Rule for the service
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${var.name}-sampling"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = var.name
  resource_arn   = "*"

  tags = var.tags
}

resource "aws_iam_role" "xray" {
  name               = "${var.name}-xray-role"
  assume_role_policy = data.aws_iam_policy_document.xray_assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "xray_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["xray.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "xray_policy" {
  role       = aws_iam_role.xray.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
