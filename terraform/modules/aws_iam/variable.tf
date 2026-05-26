variable "environment" {
  description = "The environment name"
  type        = string
}

variable "databricks_account_id" {
  description = "The Databricks account ID"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}

variable "aws_region" {
  description = "The AWS region for the resources"
  type        = string
}

variable "lakehouse_bucket_name" {
  description = "The name of the Lakehouse S3 bucket GLUE and Iceberg"
  type        = string
}