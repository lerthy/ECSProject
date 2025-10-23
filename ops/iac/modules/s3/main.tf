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
  count = var.enable_replication && var.create_buckets ? 1 : 0
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
        Resource = [aws_s3_bucket.frontend[0].arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Resource = ["${aws_s3_bucket.frontend[0].arn}/*"]
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
  count  = var.enable_replication && var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id
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

# Data source for existing frontend bucket (used when create_buckets = false)
data "aws_s3_bucket" "frontend_existing" {
  count  = var.create_buckets ? 0 : 1
  bucket = var.frontend_bucket_name
}

# S3 bucket with lifecycle to prevent destruction
# Only create if var.create_buckets is true to prevent "BucketAlreadyExists" error
resource "aws_s3_bucket" "frontend" {
  count         = var.create_buckets ? 1 : 0
  bucket        = var.frontend_bucket_name
  force_destroy = true
  tags          = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      bucket,
      tags
    ]
  }
}

# Added encryption configuration per best practices
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  count      = var.create_buckets ? 1 : 0
  bucket     = aws_s3_bucket.frontend[0].id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend[0].arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Data source for existing ALB logs bucket (used when create_buckets = false)
data "aws_s3_bucket" "alb_logs_existing" {
  count  = var.create_buckets ? 0 : 1
  bucket = var.alb_logs_bucket_name
}

# ALB logs bucket with lifecycle to prevent destruction
# Only create if var.create_buckets is true to prevent "BucketAlreadyExists" error
resource "aws_s3_bucket" "alb_logs" {
  count         = var.create_buckets ? 1 : 0
  bucket        = var.alb_logs_bucket_name
  force_destroy = true
  tags          = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      bucket,
      tags
    ]
  }
}

# Added encryption configuration per best practices
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ALB logs bucket policy
resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root" # ELB service account - dynamic lookup per best practices
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
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
        Resource = aws_s3_bucket.alb_logs[0].arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs[0].arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}


# Data source for existing CloudFront logs bucket (used when create_buckets = false)
data "aws_s3_bucket" "cloudfront_logs_existing" {
  count  = var.create_buckets ? 0 : 1
  bucket = var.cloudfront_logs_bucket_name
}

# CloudFront logs bucket with lifecycle to prevent destruction
# Only create if var.create_buckets is true to prevent "BucketAlreadyExists" error
resource "aws_s3_bucket" "cloudfront_logs" {
  count         = var.create_buckets ? 1 : 0
  bucket        = var.cloudfront_logs_bucket_name
  force_destroy = true
  tags          = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      bucket,
      tags
    ]
  }
}

# Added encryption configuration per best practices
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# CloudFront logs bucket needs ACL enabled
resource "aws_s3_bucket_acl" "cloudfront_logs" {
  count      = var.create_buckets ? 1 : 0
  bucket     = aws_s3_bucket.cloudfront_logs[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  count  = var.create_buckets ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

