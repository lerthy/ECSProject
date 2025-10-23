output "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.frontend[0].arn : data.aws_s3_bucket.frontend_existing[0].arn
}

output "frontend_bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.frontend[0].bucket : data.aws_s3_bucket.frontend_existing[0].bucket
}

output "frontend_bucket_domain_name" {
  description = "Domain name of the frontend S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.frontend[0].bucket_domain_name : data.aws_s3_bucket.frontend_existing[0].bucket_domain_name
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.alb_logs[0].arn : data.aws_s3_bucket.alb_logs_existing[0].arn
}

output "alb_logs_bucket_name" {
  description = "Name of the ALB logs S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.alb_logs[0].bucket : data.aws_s3_bucket.alb_logs_existing[0].bucket
}

output "cloudfront_logs_bucket_arn" {
  description = "ARN of the CloudFront logs S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.cloudfront_logs[0].arn : data.aws_s3_bucket.cloudfront_logs_existing[0].arn
}

output "cloudfront_logs_bucket_name" {
  description = "Name of the CloudFront logs S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.cloudfront_logs[0].bucket : data.aws_s3_bucket.cloudfront_logs_existing[0].bucket
}

output "cloudfront_logs_bucket_domain_name" {
  description = "Domain name of the CloudFront logs S3 bucket"
  value       = var.create_buckets ? aws_s3_bucket.cloudfront_logs[0].bucket_domain_name : data.aws_s3_bucket.cloudfront_logs_existing[0].bucket_domain_name
}
