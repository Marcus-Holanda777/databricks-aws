locals {
  target_bucket_id = var.environment == "prod" ? aws_s3_bucket.lakehouse_bucket_prod[0].id : aws_s3_bucket.lakehouse_bucket_dev[0].id
}

resource "aws_s3_bucket" "lakehouse_bucket_prod" {
  count         = var.environment == "prod" ? 1 : 0
  bucket        = "${var.bucket_name}-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.bucket_name}-${var.environment}-${var.aws_region}-bucket"
      Environment = var.environment
      Component   = "Storage-Lakehouse"
    },
    var.tags
  )
}


resource "aws_s3_bucket" "lakehouse_bucket_dev" {
  count         = var.environment != "prod" ? 1 : 0
  bucket        = "${var.bucket_name}-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.bucket_name}-${var.environment}-${var.aws_region}-bucket"
      Environment = var.environment
      Component   = "Storage-Lakehouse"
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "enabled" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = aws_s3_bucket.lakehouse_bucket_prod[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = aws_s3_bucket.lakehouse_bucket_prod[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = aws_s3_bucket.lakehouse_bucket_prod[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "folder_structure" {
  for_each = toset(var.subfolders)
  bucket   = local.target_bucket_id
  key      = "${each.value}/"

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.bucket_name}-${var.environment}-${var.aws_region}-folder-${each.value}"
      Environment = var.environment
      Component   = "Storage-Lakehouse"
    },
    var.tags
  )
}