output "athena_database_name" {
  description = "Athena database name"
  value       = aws_athena_database.logs.name
}

output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.logs.name
}
