terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

# S3 Replication IAM Role (only in source region)
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "replication_policy" {
  count = var.enable_replication ? 1 : 0
  name  = "s3-replication-policy"
  role  = aws_iam_role.replication[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [data.aws_s3_bucket.frontend.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Resource = ["${data.aws_s3_bucket.frontend.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = [var.replication_destination_bucket, "${var.replication_destination_bucket}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "frontend" {
  count  = var.enable_replication ? 1 : 0
  bucket = data.aws_s3_bucket.frontend.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = var.replication_destination_bucket
      storage_class = "STANDARD"
    }
    filter {
      prefix = ""
    }
    delete_marker_replication {
      status = "Enabled"
    }
  }
  depends_on = [aws_iam_role_policy.replication_policy]
}

# Data source for ELB service account - per best practices
data "aws_elb_service_account" "main" {}

# Use data source for existing S3 bucket
data "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name
}

# Only create the bucket if it doesn't exist
resource "aws_s3_bucket" "frontend" {
  count         = data.aws_s3_bucket.frontend.bucket == "" ? 1 : 0
  bucket        = var.frontend_bucket_name
  force_destroy = true
  tags          = var.tags
}

# Added encryption configuration per best practices
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = data.aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = data.aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket     = data.aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${data.aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = data.aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Use data source for existing ALB logs bucket
data "aws_s3_bucket" "alb_logs" {
  bucket = var.alb_logs_bucket_name
}

# Only create the bucket if it doesn't exist
resource "aws_s3_bucket" "alb_logs" {
  count         = data.aws_s3_bucket.alb_logs.bucket == "" ? 1 : 0
  bucket        = var.alb_logs_bucket_name
  force_destroy = true
  tags          = var.tags
}

# Added encryption configuration per best practices
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = data.aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ALB logs bucket policy
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = data.aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root" # ELB service account - dynamic lookup per best practices
        }
        Action   = "s3:PutObject"
        Resource = "${data.aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${data.aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = data.aws_s3_bucket.alb_logs.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = data.aws_s3_bucket.alb_logs.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${data.aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}


# Use data source for existing CloudFront logs bucket
data "aws_s3_bucket" "cloudfront_logs" {
  bucket = var.cloudfront_logs_bucket_name
}

# Only create the bucket if it doesn't exist
resource "aws_s3_bucket" "cloudfront_logs" {
  count         = data.aws_s3_bucket.cloudfront_logs.bucket == "" ? 1 : 0
  bucket        = var.cloudfront_logs_bucket_name
  force_destroy = true
  tags          = var.tags
}

# Added encryption configuration per best practices
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = data.aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# CloudFront logs bucket needs ACL enabled
resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket     = data.aws_s3_bucket.cloudfront_logs.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = data.aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

