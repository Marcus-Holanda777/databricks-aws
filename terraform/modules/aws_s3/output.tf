output "bucket_id" {
  description = "ID do bucket criado dependendo do ambiente"
  value       = var.environment == "prod" ? aws_s3_bucket.lakehouse_bucket_prod[0].id : aws_s3_bucket.lakehouse_bucket_dev[0].id
}

output "bucket_arn" {
  description = "ARN do bucket criado dependendo do ambiente"
  value       = var.environment == "prod" ? aws_s3_bucket.lakehouse_bucket_prod[0].arn : aws_s3_bucket.lakehouse_bucket_dev[0].arn
}

output "bucket_name" {
  description = "Nome do bucket criado dependendo do ambiente"
  value       = var.environment == "prod" ? aws_s3_bucket.lakehouse_bucket_prod[0].bucket : aws_s3_bucket.lakehouse_bucket_dev[0].bucket
}