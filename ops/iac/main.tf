# Root Terraform Composition

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "bardhi-ecom-terraform-state-dev"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}

module "s3" {
  source                      = "./modules/s3"
  frontend_bucket_name        = var.frontend_bucket_name
  alb_logs_bucket_name        = var.alb_logs_bucket_name
  cloudfront_logs_bucket_name = var.cloudfront_logs_bucket_name
  tags                        = var.tags
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

module "alb" {
  source                     = "./modules/alb"
  name                       = var.alb_name
  security_group_ids         = [module.vpc.nat_gateway_id] # Replace with actual SGs
  access_logs_bucket         = module.s3.alb_logs_bucket_arn
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
  access_logs_bucket         = module.s3.alb_logs_bucket_arn
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

<<<<<<< HEAD


# Route 53 Failover for Warm Standby (using module)

module "route53_failover" {
  source                = "./modules/route53"
  primary_alb_dns_name  = module.alb.alb_dns_name
  standby_alb_dns_name  = module.alb_standby.alb_dns_name
  alb_zone_id           = var.alb_zone_id
  route53_zone_id       = var.route53_zone_id
  api_dns_name          = var.api_dns_name
  health_check_path     = var.health_check_path
  tags                  = var.tags
}

=======
>>>>>>> d097566f3190fa235805e7827d15d2c87211160e
module "cloudfront" {
  source                  = "./modules/cloudfront"
  s3_domain_name          = module.s3.frontend_bucket_arn
  logs_bucket_domain_name = module.s3.cloudfront_logs_bucket_arn
  tags                    = var.tags
}

module "cloudwatch" {
  source                     = "./modules/cloudwatch"
  name                       = var.ecs_name
  log_retention_days         = var.log_retention_days
  tags                       = var.tags
  dashboard_body             = var.dashboard_body
  ecs_cpu_threshold          = var.ecs_cpu_threshold
  ecs_cluster_name           = module.ecs.cluster_id
  sns_topic_arn              = module.sns.sns_topic_arn
  alb_name                   = var.alb_name
  environment                = var.environment
  cloudfront_distribution_id = var.cloudfront_distribution_id
}

module "sns" {
  source          = "./modules/sns"
  name            = "alerts"
  tags            = var.tags
  sns_alert_email = var.sns_alert_email
  slack_webhook   = var.sns_slack_webhook
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

module "monitoring_alarms" {
  source      = "./modules/monitoring_alarms"
  alb_name    = var.alb_name
  environment = var.environment
  tags        = var.tags
}

module "cicd" {
  source                     = "./modules/cicd"
  github_owner               = var.github_owner
  github_repo                = var.github_repo
  github_branch              = var.github_branch
  github_token               = var.github_token
  terraform_state_bucket     = "bardhi-ecom-terraform-state-dev"
  terraform_state_key        = "state/terraform.tfstate"
  ecr_repository_url         = module.ecr.repository_url
  ecs_cluster_name           = module.ecs.cluster_name
  ecs_service_name           = module.ecs.service_name
  frontend_bucket_name       = module.s3.frontend_bucket_name
  cloudfront_distribution_id = module.cloudfront.distribution_id
  alb_name                   = var.alb_name
  app_health_url             = "https://${module.alb.dns_name}"
  sns_topic_arn              = module.sns.topic_arn
  tags                       = var.tags
}
