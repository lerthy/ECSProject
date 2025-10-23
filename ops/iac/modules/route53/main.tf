# Route 53 Failover Module

resource "aws_route53_health_check" "alb_primary" {
  fqdn              = var.primary_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  tags              = var.tags
}

resource "aws_route53_health_check" "alb_standby" {
  fqdn              = var.standby_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  tags              = var.tags
}

# Geographic routing for global traffic distribution
resource "aws_route53_record" "api_geographic_primary" {
  zone_id        = var.route53_zone_id
  name           = var.api_dns_name
  type           = "A"
  set_identifier = "primary-geographic"
  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  geolocation_routing_policy {
    continent = "NA"  # North America
  }
  health_check_id = aws_route53_health_check.alb_primary.id
}

resource "aws_route53_record" "api_geographic_secondary" {
  zone_id        = var.route53_zone_id
  name           = var.api_dns_name
  type           = "A"
  set_identifier = "secondary-geographic"
  alias {
    name                   = var.standby_alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  geolocation_routing_policy {
    continent = "EU"  # Europe
  }
  health_check_id = aws_route53_health_check.alb_standby.id
}

# Weighted routing for load balancing between regions
resource "aws_route53_record" "api_weighted_primary" {
  zone_id        = var.route53_zone_id
  name           = var.api_dns_name
  type           = "A"
  set_identifier = "primary-weighted"
  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  weighted_routing_policy {
    weight = 80  # 80% traffic to primary
  }
  health_check_id = aws_route53_health_check.alb_primary.id
}

resource "aws_route53_record" "api_weighted_standby" {
  zone_id        = var.route53_zone_id
  name           = var.api_dns_name
  type           = "A"
  set_identifier = "standby-weighted"
  alias {
    name                   = var.standby_alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  weighted_routing_policy {
    weight = 20  # 20% traffic to standby
  }
  health_check_id = aws_route53_health_check.alb_standby.id
}

resource "aws_route53_record" "api_failover_primary" {
  zone_id        = var.route53_zone_id
  name           = var.api_dns_name
  type           = "A"
  set_identifier = "primary"
  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.alb_primary.id
}

resource "aws_route53_record" "api_failover_standby" {
  zone_id        = var.route53_zone_id
  name           = var.api_dns_name
  type           = "A"
  set_identifier = "standby"
  alias {
    name                   = var.standby_alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.alb_standby.id
}
