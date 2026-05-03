output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS connection endpoint"
  sensitive   = true   # won't print in logs
}

output "db_name" {
  value = aws_db_instance.main.db_name
}