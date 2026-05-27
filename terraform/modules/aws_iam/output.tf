output "cross_account_role_arn" {
  description = "ARN da Role Cross-Account que o Databricks usa para criar a infra do Workspace"
  value       = aws_iam_role.cross_account_role.arn
}

output "unity_catalog_role_arn" {
  description = "ARN da Role que o Unity Catalog usa para acessar os buckets S3 (Bronze, Silver, Gold)"
  value       = aws_iam_role.unity_catalog_role.arn
}

output "storage_credential_external_id" {
  description = "ID Externo usado para validar a credencial de armazenamento de forma segura"
  value       = var.databricks_account_id
}

output "databricks_glue_role_arn" {
  description = "ARN da Role que o Databricks usa para acessar o AWS Glue Data Catalog"
  value       = aws_iam_role.databricks_glue_role.arn
}

output "databricks_glue_role_name" {
  description = "NOME da Role que o Databricks usa para acessar o AWS Glue Data Catalog"
  value       = aws_iam_role.databricks_glue_role.name
}

output "iam_aws_account_id" {
  description = "ID conta AWS"
  value       = data.aws_caller_identity.current.id
}