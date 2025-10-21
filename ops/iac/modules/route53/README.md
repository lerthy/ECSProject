# Route 53 Failover Module

This module creates Route 53 health checks and failover records for a warm standby architecture.

## Inputs
- `primary_alb_dns_name`: DNS name of the primary ALB
- `standby_alb_dns_name`: DNS name of the standby ALB
- `alb_zone_id`: Zone ID for the ALB
- `route53_zone_id`: Route 53 Hosted Zone ID
- `api_dns_name`: DNS name for the API record
- `health_check_path`: Path for the health check (default: "/")
- `tags`: Tags to apply to resources

## Outputs
- `primary_health_check_id`: ID of the primary ALB health check
- `standby_health_check_id`: ID of the standby ALB health check
- `primary_record_fqdn`: FQDN of the primary failover record
- `standby_record_fqdn`: FQDN of the standby failover record
