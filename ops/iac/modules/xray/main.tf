terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

# XRay group with lifecycle to prevent destruction
resource "aws_xray_group" "default" {
  filter_expression = "service(\"${var.name}\")"
  group_name        = var.name
  insights_configuration {
    insights_enabled = true
  }
  tags = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      group_name,
      tags
    ]
  }
}

# Use data source for existing XRay IAM role
data "aws_iam_role" "xray" {
  name = "${var.name}-xray-role"
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
  role       = data.aws_iam_role.xray.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
