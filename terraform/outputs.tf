output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "frontend_bucket_arn" {
  description = "Frontend S3 bucket ARN"
  value       = module.s3.frontend_bucket_arn
}

output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = module.ecs.cluster_id
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = module.sns.sns_topic_arn
}

output "athena_database_name" {
  description = "Athena database name"
  value       = module.athena.athena_database_name
}
