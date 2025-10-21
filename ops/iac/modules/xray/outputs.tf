output "xray_group_name" {
  description = "X-Ray group name"
  value       = aws_xray_group.default.group_name
}

output "xray_role_arn" {
  description = "IAM role ARN for X-Ray"
  value       = aws_iam_role.xray.arn
}
