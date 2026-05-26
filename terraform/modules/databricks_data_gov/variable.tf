variable "environment" {
  type        = string
  description = "Ambiente atual (dev ou prod)"
}

variable "unity_catalog_role_arn" {
  type        = string
  description = "ARN da Role do IAM que o Unity Catalog assume para acessar o S3"
}

variable "bucket_raw_id" { type = string }
variable "bucket_bronze_id" { type = string }
variable "bucket_silver_id" { type = string }
variable "bucket_gold_id" { type = string }

variable "admin_group_name" {
  type        = string
  description = "Nome do grupo ADMIN vindo do modulo de usuarios"
}

variable "user_group_name" {
  type        = string
  description = "Nome do grupo USER vindo do modulo de usuarios"
}

variable "db_username" {
  type        = string
  description = "Nome de usuário do banco de dados"
}

variable "db_name" {
  type        = string
  description = "Nome do banco de dados"
}

variable "db_password" {
  type        = string
  description = "Senha do banco de dados"
}

variable "db_instance_endpoint" {
  type        = string
  description = "Endpoint da instância do RDS"
}

variable "databricks_glue_role_arn" {
  type        = string
  description = "ARN da Role do IAM que o Databricks assume para acessar o AWS Glue"
}

variable "bucket_glue_data_id" {
  type        = string
  description = "ID do bucket S3 onde os dados do Glue serão armazenados"
}

variable "aws_region" {
  type        = string
  description = "Regiao AWS onde os recursos serão provisionados"
}