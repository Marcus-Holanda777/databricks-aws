variable "databricks_account_id" {
  type        = string
  description = "ID da conta Databricks"
}

variable "databricks_workspace_id" {
  type        = string
  description = "ID do Workspace Databricks"
}

variable "aws_region" {
  type        = string
  description = "Região AWS onde os recursos serão implantados"
}

variable "environment" {
  type        = string
  description = "Ambiente de deploy"
}

variable "vpc_endpoint_service_name" {
  type        = string
  description = "Nome do serviço do endpoint VPC para o RDS Serverless"
}