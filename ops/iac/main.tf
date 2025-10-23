
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Provider alias for eu-north-1 (DR region)
provider "aws" {
  alias  = "dr"
  region = "eu-north-1"
}

# DMS for cross-region DB replication (modularized)
module "dms" {
  source                     = "./modules/dms"
  replication_instance_id    = "cross-region-dms-instance"
  allocated_storage          = 50
  replication_instance_class = "dms.t3.medium"
  engine_version             = "3.4.7"
  publicly_accessible        = false
  multi_az                   = true
  auto_minor_version_upgrade = true
  tags                       = var.tags

  source_endpoint_id   = "source-db-endpoint"
  source_engine_name   = "postgres"
  source_username      = var.rds_source_username
  source_password      = var.rds_source_password
  source_server_name   = var.rds_source_endpoint
  source_port          = 5432
  source_database_name = var.rds_source_db_name
  source_ssl_mode      = "require"

  target_endpoint_id   = "target-db-endpoint"
  target_engine_name   = "postgres"
  target_username      = var.rds_target_username
  target_password      = var.rds_target_password
  target_server_name   = var.rds_target_endpoint
  target_port          = 5432
  target_database_name = var.rds_target_db_name
  target_ssl_mode      = "require"

  replication_task_id       = "cross-region-task"
  migration_type            = "full-load-and-cdc"
  table_mappings            = file("${path.module}/dms-table-mappings.json")
  replication_task_settings = file("${path.module}/dms-task-settings.json")
}

module "s3" {
  source                         = "./modules/s3"
  frontend_bucket_name           = var.frontend_bucket_name
  alb_logs_bucket_name           = var.alb_logs_bucket_name
  cloudfront_logs_bucket_name    = var.cloudfront_logs_bucket_name
  tags                           = var.tags
  enable_replication             = var.enable_s3_replication
  replication_role_arn           = "" # Not needed for source, created in module
  replication_destination_bucket = var.replication_destination_bucket_arn
}

# S3 in eu-north-1 (DR region)
module "s3_dr" {
  source                      = "./modules/s3"
  providers                   = { aws = aws.dr }
  frontend_bucket_name        = var.frontend_bucket_name_dr
  alb_logs_bucket_name        = var.alb_logs_bucket_name_dr
  cloudfront_logs_bucket_name = var.cloudfront_logs_bucket_name_dr
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
  tags            = var.tags
}

# VPC in eu-north-1 (DR region)
module "vpc_dr" {
  source          = "./modules/vpc"
  providers       = { aws = aws.dr }
  name            = var.vpc_name_dr
  cidr_block      = var.vpc_cidr_block_dr
  public_subnets  = var.public_subnets_dr
  private_subnets = var.private_subnets_dr
  db_subnets      = var.db_subnets_dr
  azs             = var.azs_dr
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

# RDS in eu-north-1 (DR region)
module "rds_dr" {
  source                       = "./modules/rds"
  providers                    = { aws = aws.dr }
  name                         = "${var.ecs_name}-db-dr"
  vpc_id                       = module.vpc_dr.vpc_id
  private_subnet_ids           = module.vpc_dr.db_subnet_ids
  app_security_group_id        = module.vpc_dr.ecs_security_group_id
  database_name                = "ecommerce"
  instance_class               = var.rds_instance_class
  engine_version               = var.rds_engine_version
  allocated_storage            = var.rds_allocated_storage
  max_allocated_storage        = var.rds_max_allocated_storage
  multi_az                     = false
  backup_retention_period      = 3
  deletion_protection          = var.rds_deletion_protection
  skip_final_snapshot          = var.environment == "dev" ? true : false
  monitoring_interval          = 0
  performance_insights_enabled = false
  alarm_actions                = [module.sns_dr.sns_topic_arn]
  create_read_replica          = false
  read_replica_instance_class  = var.rds_instance_class
  # Cross-region replica config
  create_cross_region_replica = var.create_cross_region_replica
  replicate_source_db         = var.replicate_source_db
  tags = merge(var.tags, {
    Purpose = "Standby-DR"
    Tier    = "Database"
  })
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

# ALB in eu-north-1 (DR region)
module "alb_dr" {
  source                     = "./modules/alb"
  providers                  = { aws = aws.dr }
  name                       = "${var.alb_name}-dr"
  security_group_ids         = [module.vpc_dr.alb_security_group_id]
  access_logs_bucket         = module.s3_dr.alb_logs_bucket_name
  public_subnet_ids          = module.vpc_dr.public_subnet_ids
  enable_deletion_protection = true
  tags                       = var.tags
  vpc_id                     = module.vpc_dr.vpc_id
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
  container_definitions = local.container_definition
  desired_count         = var.desired_count
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_security_group_id]
  target_group_arn      = module.alb.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
}

# ECS in eu-north-1 (DR region)
module "ecs_dr" {
  source                = "./modules/ecs"
  providers             = { aws = aws.dr }
  name                  = "${var.ecs_name}-dr"
  tags                  = var.tags
  cpu                   = var.cpu
  memory                = var.memory
  container_definitions = local.container_definition
  desired_count         = 1
  private_subnet_ids    = module.vpc_dr.private_subnet_ids
  security_group_ids    = [module.vpc_dr.ecs_security_group_id]
  target_group_arn      = module.alb_dr.target_group_arn
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
  container_definitions = local.container_definition_standby
  desired_count         = 1 # Minimal standby
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_security_group_id]
  target_group_arn      = module.alb_standby.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
}

module "route53_failover" {
  source               = "./modules/route53"
  primary_alb_dns_name = module.alb.alb_dns_name
  standby_alb_dns_name = module.alb_dr.alb_dns_name
  alb_zone_id          = var.alb_zone_id
  route53_zone_id      = var.route53_zone_id
  api_dns_name         = var.api_dns_name
  health_check_path    = var.health_check_path
  tags                 = var.tags
}

module "cloudfront" {
  source                  = "./modules/cloudfront"
  s3_domain_name          = module.s3.frontend_bucket_domain_name
  logs_bucket_domain_name = module.s3.cloudfront_logs_bucket_domain_name
  web_acl_id              = aws_wafv2_web_acl.cloudfront.arn
  tags                    = var.tags
}

# CloudFront in eu-north-1 (DR region)
module "cloudfront_dr" {
  source                  = "./modules/cloudfront"
  providers               = { aws = aws.dr }
  s3_domain_name          = module.s3_dr.frontend_bucket_domain_name
  logs_bucket_domain_name = module.s3_dr.cloudfront_logs_bucket_domain_name
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

# CloudWatch in eu-north-1 (DR region)
module "cloudwatch_dr" {
  source                     = "./modules/cloudwatch"
  providers                  = { aws = aws.dr }
  name                       = var.ecs_name
  log_retention_days         = var.log_retention_days
  tags                       = var.tags
  dashboard_body             = var.dashboard_body
  ecs_cpu_threshold          = var.ecs_cpu_threshold
  ecs_cluster_name           = module.ecs_dr.cluster_id
  sns_topic_arn              = module.sns_dr.sns_topic_arn
  alb_name                   = "${var.alb_name}-dr"
  environment                = var.environment
  cloudfront_distribution_id = module.cloudfront_dr.cloudfront_distribution_id
}

module "sns" {
  source          = "./modules/sns"
  name            = "alerts"
  tags            = var.tags
  sns_alert_email = var.sns_alert_email
  slack_webhook   = var.sns_slack_webhook
}

# SNS in eu-north-1 (DR region)
module "sns_dr" {
  source          = "./modules/sns"
  providers       = { aws = aws.dr }
  name            = "alerts-dr"
  tags            = var.tags
  sns_alert_email = var.sns_alert_email
  slack_webhook   = var.sns_slack_webhook
}

module "xray" {
  source = "./modules/xray"
  name   = var.ecs_name
  tags   = var.tags
}

# X-Ray in eu-north-1 (DR region)
module "xray_dr" {
  source    = "./modules/xray"
  providers = { aws = aws.dr }
  name      = var.ecs_name
  tags      = var.tags
}

module "athena" {
  source                 = "./modules/athena"
  database_name          = var.athena_database_name
  s3_bucket              = module.s3.alb_logs_bucket_name
  cloudfront_logs_bucket = module.s3.cloudfront_logs_bucket_name
  workgroup_name         = var.athena_workgroup_name
  output_location        = var.athena_output_location
  tags                   = var.tags
}

# Athena in eu-north-1 (DR region)
module "athena_dr" {
  source                 = "./modules/athena"
  providers              = { aws = aws.dr }
  database_name          = var.athena_database_name
  s3_bucket              = module.s3_dr.alb_logs_bucket_name
  cloudfront_logs_bucket = module.s3_dr.cloudfront_logs_bucket_name
  workgroup_name         = var.athena_workgroup_name
  output_location        = var.athena_output_location
  tags                   = var.tags
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

# Monitoring/Alarms in eu-north-1 (DR region)
module "monitoring_alarms_dr" {
  source                     = "./modules/monitoring_alarms"
  providers                  = { aws = aws.dr }
  alb_name                   = "${var.alb_name}-dr"
  alb_arn                    = module.alb_dr.alb_arn
  sns_topic_arn              = module.sns_dr.sns_topic_arn
  cloudfront_distribution_id = module.cloudfront_dr.cloudfront_distribution_id
  environment                = var.environment
  tags                       = var.tags
}

module "cicd" {
  source                     = "../iac/cicd"
  aws_region                 = data.aws_region.current.name
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

# ECR in eu-north-1 (DR region)
module "ecr_dr" {
  source      = "./modules/ecr"
  providers   = { aws = aws.dr }
  environment = var.environment
  tags        = var.tags
}
