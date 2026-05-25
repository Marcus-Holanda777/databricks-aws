variable "environment" {
  type        = string
  description = "Ambiente de deploy"
}

variable "db_name" {
  type        = string
  description = "Nome da base de dados"
}

variable "db_username" {
  type        = string
  description = "Nome de usuário da base de dados"
}

variable "db_password" {
  type        = string
  description = "Senha da base de dados"
}

variable "postgres_subnets_name" {
  type        = string
  description = "Nome do grupo de subnets para o Postgres"
}

variable "postgres_security_group_id" {
  type        = string
  description = "ID do Security Group para o Postgres"
}

variable "multi_az_nat" {
  type        = bool
  description = "Indica se a instância do RDS deve ser implantada em múltiplas zonas de disponibilidade"
}

variable "tags" {
  type        = map(string)
  description = "Tags para aplicar aos recursos do RDS"
}

variable "aws_region" {
  type        = string
  description = "Região AWS onde os recursos serão implantados"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs das subnets privadas para o RDS"
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC onde o RDS será implantado"
}