# Cost Optimization: S3 Lifecycle, Fargate Spot, Tagging

# S3 Lifecycle for log storage
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = module.s3.alb_logs_bucket_arn
  rule {
    id     = "log-expiry"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

# Fargate Spot for ECS
resource "aws_ecs_service" "api_spot" {
  count           = 0 # Example: set to 1 to enable spot
  name            = "${var.ecs_name}-spot"
  cluster         = module.ecs.cluster_id
  task_definition = module.ecs.task_definition_arn
  desired_count   = 1
  launch_type     = "FARGATE"
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
  network_configuration {
    subnets          = module.vpc.private_subnet_ids
    security_groups  = [module.vpc.nat_gateway_id] # Replace with actual SGs
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
  tags = var.tags
}

# Tagging and right-sizing are handled via variables and tags in all modules
