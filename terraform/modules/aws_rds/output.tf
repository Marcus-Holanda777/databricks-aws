output "db_instance_endpoint" {
  value       = aws_db_instance.postgres_db.endpoint
  description = "Endpoint da instância do RDS"
}

output "vpc_endpoint_service_name" {
  value       = aws_vpc_endpoint_service.postgres_serverless_service.service_name
  description = "Nome do serviço do endpoint VPC para o RDS Serverless"
}