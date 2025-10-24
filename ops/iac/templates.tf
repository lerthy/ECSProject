# Template configurations for ECS container definitions and other dynamic content

# Get current AWS region
data "aws_region" "current" {}

# Template for ECS container definition with RDS integration
data "template_file" "container_definition" {
  template = file("${path.module}/container-definition.json.tpl")
  vars = {
    container_name              = var.container_name
    image_uri                   = "${module.ecr.repository_url}:latest"
    cpu                         = var.cpu
    memory                      = var.memory
    container_port              = var.container_port
    environment                 = var.environment
    node_env                    = var.environment == "prod" ? "production" : "development"
    db_host                     = module.rds.connection_info.host
    db_port                     = "5432"
    db_name                     = "ecommerce"
    db_username                 = "postgres"
    aws_region                  = data.aws_region.current.name
    secrets_manager_secret_name = "ecommerce/${var.environment}/database"
    secrets_manager_secret_arn  = module.rds.secrets_manager_secret_arn
    log_group                   = "/ecs/${var.ecs_name}"
    xray_tracing_name           = var.ecs_name
  }
}

# Template for standby ECS container definition with RDS standby integration
data "template_file" "container_definition_standby" {
  template = file("${path.module}/container-definition.json.tpl")
  vars = {
    container_name              = var.container_name
    image_uri                   = "${module.ecr.repository_url}:latest"
    cpu                         = var.cpu
    memory                      = var.memory
    container_port              = var.container_port
    environment                 = var.environment
    node_env                    = var.environment == "prod" ? "production" : "development"
    db_host                     = module.rds_standby.connection_info.host
    db_port                     = "5432"
    db_name                     = "ecommerce"
    db_username                 = "postgres"
    aws_region                  = data.aws_region.current.name
    secrets_manager_secret_name = "ecommerce/${var.environment}/database-standby"
    secrets_manager_secret_arn  = module.rds_standby.secrets_manager_secret_arn
    log_group                   = "/ecs/${var.ecs_name}-standby"
    xray_tracing_name           = "${var.ecs_name}-standby"
  }
}
