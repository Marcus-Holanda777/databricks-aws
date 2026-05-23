output "vpc_id" {
  value       = aws_vpc.databricks_vpc.id
  description = "ID da VPC analitica criada"
}

output "private_subnet_ids" {
  value       = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  description = "Lista contendo os IDs das subnets privadas onde o Spark rodara"
}

output "security_group_id" {
  value       = aws_security_group.databricks_sg.id
  description = "ID do Security Group criado para o workspace"
}