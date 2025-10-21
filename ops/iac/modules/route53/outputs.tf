output "primary_health_check_id" {
  description = "ID of the primary ALB health check"
  value       = aws_route53_health_check.alb_primary.id
}

output "standby_health_check_id" {
  description = "ID of the standby ALB health check"
  value       = aws_route53_health_check.alb_standby.id
}

output "primary_record_fqdn" {
  description = "FQDN of the primary failover record"
  value       = aws_route53_record.api_failover_primary.fqdn
}

output "standby_record_fqdn" {
  description = "FQDN of the standby failover record"
  value       = aws_route53_record.api_failover_standby.fqdn
}
