variable "environment" {
  type        = string
  description = "Ambiente atual (dev ou prod)"
}

variable "databricks_account_id" {
  type        = string
  description = "ID da conta copiado do Databricks Account Console"
}

variable "cross_account_role_arn" {
  type        = string
  description = "ARN da Role do IAM criada para o Databricks gerenciar os recursos"
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC criada no módulo de rede"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Lista de IDs das Subnets Privadas onde os clusters Spark vão rodar"
}

variable "security_group_id" {
  type        = string
  description = "ID do Security Group padrão criado para a VPC"
}

variable "aws_region" {
  type        = string
  description = "Região onde os recursos do Databricks serão criados"
}