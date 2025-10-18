# Route 53 Failover for Warm Standby

resource "aws_route53_health_check" "alb_primary" {
  fqdn              = module.alb.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  tags              = var.tags
}

resource "aws_route53_health_check" "alb_standby" {
  fqdn              = module.alb_standby.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  tags              = var.tags
}

resource "aws_route53_record" "api_failover_primary" {
  zone_id = var.route53_zone_id
  name    = var.api_dns_name
  type    = "A"
  set_identifier = "primary"
  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.alb_primary.id
}

resource "aws_route53_record" "api_failover_standby" {
  zone_id = var.route53_zone_id
  name    = var.api_dns_name
  type    = "A"
  set_identifier = "standby"
  alias {
    name                   = module.alb_standby.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.alb_standby.id
}
