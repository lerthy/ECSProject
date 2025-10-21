output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}
output "frontend_bucket_arn" {
  value = module.s3.frontend_bucket_arn
}
output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}
output "sns_topic_arn" {
  value = module.sns.sns_topic_arn
}
output "athena_database_name" {
  value = module.athena.athena_database_name
}
