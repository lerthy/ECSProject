# X-Ray Module
resource "aws_xray_group" "default" {
  filter_expression = ""
  group_name        = var.name
  insights_configuration {
    insights_enabled = true
  }
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
