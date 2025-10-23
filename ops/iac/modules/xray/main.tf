terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

# Use data source for existing XRay group
data "aws_xray_group" "default" {
  group_name = var.name
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
  role       = aws_iam_role.xray.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
