provider "aws" {
  region = var.region
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
  db_subnets      = var.db_subnets
  azs             = var.azs
  container_port  = var.container_port
  tags            = var.tags
}

module "rds" {
  source = "./modules/rds"

  name                  = "${var.ecs_name}-db"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.db_subnet_ids
  app_security_group_id = module.vpc.ecs_security_group_id

  # Database configuration
  database_name  = "ecommerce"
  instance_class = var.rds_instance_class
  engine_version = var.rds_engine_version

  # Storage
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  # Reliability settings
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.environment == "dev" ? true : false

  # Monitoring
  monitoring_interval          = 60
  performance_insights_enabled = true
  alarm_actions                = [module.sns.sns_topic_arn]

  # Read replica for production
  create_read_replica         = var.environment == "prod" ? true : false
  read_replica_instance_class = var.rds_instance_class

  tags = var.tags
}

# Standby RDS (Warm Standby for Database)
module "rds_standby" {
  source = "./modules/rds"

  name                  = "${var.ecs_name}-db-standby"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.db_subnet_ids
  app_security_group_id = module.vpc.ecs_security_group_id

  # Database configuration - same as primary
  database_name  = "ecommerce"
  instance_class = var.rds_instance_class
  engine_version = var.rds_engine_version

  # Storage - smaller for standby
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  # Reliability settings - less frequent backups for standby
  multi_az                = false # Single AZ for standby to reduce costs
  backup_retention_period = 3     # Shorter retention for standby
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.environment == "dev" ? true : false

  # Monitoring - basic monitoring for standby
  monitoring_interval          = 0     # No enhanced monitoring for standby
  performance_insights_enabled = false # Disabled for standby
  alarm_actions                = [module.sns.sns_topic_arn]

  # No read replica for standby
  create_read_replica         = false
  read_replica_instance_class = var.rds_instance_class

  tags = merge(var.tags, {
    Purpose = "Standby"
    Tier    = "Database"
  })
}

module "alb" {
  source                     = "./modules/alb"
  name                       = var.alb_name
  security_group_ids         = [module.vpc.alb_security_group_id]
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
  security_group_ids         = [module.vpc.alb_security_group_id]
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
  container_definitions = data.template_file.container_definition.rendered
  desired_count         = var.desired_count
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_security_group_id]
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
  container_definitions = data.template_file.container_definition_standby.rendered
  desired_count         = 1 # Minimal standby
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_security_group_id]
  target_group_arn      = module.alb_standby.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
}

# Route 53 Failover for Warm Standby (commented out due to access restrictions)
# Uncomment when you have access to the Route53 hosted zone

# module "route53_failover" {
#   source               = "./modules/route53"
#   primary_alb_dns_name = module.alb.alb_dns_name
#   standby_alb_dns_name = module.alb_standby.alb_dns_name
#   alb_zone_id          = var.alb_zone_id
#   route53_zone_id      = var.route53_zone_id
#   api_dns_name         = var.api_dns_name
#   health_check_path    = var.health_check_path
#   tags                 = var.tags
# }

module "cloudfront" {
  source                  = "./modules/cloudfront"
  s3_domain_name          = module.s3.frontend_bucket_domain_name
  alb_domain_name         = module.alb.alb_dns_name
  logs_bucket_domain_name = module.s3.cloudfront_logs_bucket_domain_name
  web_acl_id              = aws_wafv2_web_acl.cloudfront.arn
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
  s3_bucket       = module.s3.alb_logs_bucket_name
  workgroup_name  = var.athena_workgroup_name
  output_location = var.athena_output_location
  tags            = var.tags
}

module "monitoring_alarms" {
  source                     = "./modules/monitoring_alarms"
  alb_name                   = var.alb_name
  alb_arn                    = module.alb.alb_arn
  sns_topic_arn              = module.sns.sns_topic_arn
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
  environment                = var.environment
  tags                       = var.tags
}

module "cicd" {
  source                     = "./modules/codebuild"
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
  app_health_url             = "https://${module.alb.alb_dns_name}"
  sns_topic_arn              = module.sns.sns_topic_arn
  tags                       = var.tags
}

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  tags        = var.tags
}
