data "databricks_aws_bucket_policy" "this" {
  bucket = aws_s3_bucket.root_storage.id
}

data "aws_caller_identity" "current" {}