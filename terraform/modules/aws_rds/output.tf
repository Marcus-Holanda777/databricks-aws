output "db_instance_endpoint" {
  value       = aws_db_instance.postgres_db.endpoint
  description = "Endpoint da instância do RDS"
}