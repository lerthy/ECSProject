# Root Terraform Composition

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

module "vpc" {
  source          = "./modules/vpc"
  name            = var.vpc_name
  cidr_block      = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
  tags            = var.tags
}

module "s3" {
  source                      = "./modules/s3"
  frontend_bucket_name        = var.frontend_bucket_name
  alb_logs_bucket_name        = var.alb_logs_bucket_name
  cloudfront_logs_bucket_name = var.cloudfront_logs_bucket_name
  tags                        = var.tags
}

module "alb" {
  source                     = "./modules/alb"
  name                       = var.alb_name
  security_group_ids         = [module.vpc.nat_gateway_id] # Replace with actual SGs
  access_logs_bucket         = module.s3.alb_logs_bucket_name
  public_subnet_ids          = module.vpc.public_subnet_ids
  enable_deletion_protection = true
  tags                       = var.tags
  vpc_id                     = module.vpc.vpc_id
  target_port                = var.target_port
  health_check_path          = var.health_check_path
}

# Standby ALB (Warm Standby)
module "alb_standby" {
  source                     = "./modules/alb"
  name                       = "${var.alb_name}-standby"
  security_group_ids         = [module.vpc.nat_gateway_id] # Replace with actual SGs
  access_logs_bucket         = module.s3.alb_logs_bucket_name
  public_subnet_ids          = module.vpc.public_subnet_ids
  enable_deletion_protection = true
  tags                       = var.tags
  vpc_id                     = module.vpc.vpc_id
  target_port                = var.target_port
  health_check_path          = var.health_check_path
}

module "ecs" {
  source                = "./modules/ecs"
  name                  = var.ecs_name
  tags                  = var.tags
  cpu                   = var.cpu
  memory                = var.memory
  container_definitions = var.container_definitions
  desired_count         = var.desired_count
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.nat_gateway_id] # Replace with actual SGs
  target_group_arn      = module.alb.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
}

# Standby ECS Service (Warm Standby)
module "ecs_standby" {
  source                = "./modules/ecs"
  name                  = "${var.ecs_name}-standby"
  tags                  = var.tags
  cpu                   = var.cpu
  memory                = var.memory
  container_definitions = var.container_definitions
  desired_count         = 1 # Minimal standby
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.nat_gateway_id] # Replace with actual SGs
  target_group_arn      = module.alb_standby.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
}

module "cloudfront" {
  source                  = "./modules/cloudfront"
  s3_domain_name          = module.s3.frontend_bucket_arn
  origin_access_identity  = "<REPLACE_WITH_OAI>"
  logs_bucket_domain_name = module.s3.cloudfront_logs_bucket_arn
  tags                    = var.tags
}

module "cloudwatch" {
  source             = "./modules/cloudwatch"
  name               = var.ecs_name
  log_retention_days = var.log_retention_days
  tags               = var.tags
  dashboard_body     = var.dashboard_body
  ecs_cpu_threshold  = var.ecs_cpu_threshold
  ecs_cluster_name   = module.ecs.cluster_id
  sns_topic_arn      = module.sns.sns_topic_arn
}

module "sns" {
  source        = "./modules/sns"
  name          = "alerts"
  tags          = var.tags
  email         = var.sns_email
  slack_webhook = var.sns_slack_webhook
}

module "xray" {
  source = "./modules/xray"
  name   = var.ecs_name
  tags   = var.tags
}

module "athena" {
  source          = "./modules/athena"
  database_name   = var.athena_database_name
  s3_bucket       = module.s3.alb_logs_bucket_arn
  workgroup_name  = var.athena_workgroup_name
  output_location = var.athena_output_location
  tags            = var.tags
}

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
