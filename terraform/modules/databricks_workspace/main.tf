resource "aws_s3_bucket" "root_storage" {
  bucket        = "mvsh-dbx-root-storage-mvsh-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment == "dev" ? true : false

  tags = {
    Name        = "mvsh-dbx-root-storage-mvsh-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
    Environment = var.environment
    Region      = var.aws_region
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.root_storage.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.root_storage.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket     = aws_s3_bucket.root_storage.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.state]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "root_storage_bucket" {
  bucket = aws_s3_bucket.root_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "root_storage_block" {
  bucket                  = aws_s3_bucket.root_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "root_storage_policy" {
  bucket = aws_s3_bucket.root_storage.id
  policy = data.databricks_aws_bucket_policy.this.json

  depends_on = [ aws_s3_bucket_public_access_block.root_storage_block ]
}

resource "databricks_mws_storage_configurations" "this" {
  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.root_storage.bucket
  storage_configuration_name = "dbx-storage-mvsh-${var.environment}"
}

resource "databricks_mws_networks" "this" {
  account_id         = var.databricks_account_id
  network_name       = "dbx-network-mvsh-${var.environment}"
  security_group_ids = [var.security_group_id]
  subnet_ids         = var.subnet_ids
  vpc_id             = var.vpc_id
}

resource "databricks_mws_credentials" "this" {
  role_arn         = var.cross_account_role_arn
  credentials_name = "dbx-credentials-${var.environment}"

  depends_on = [ time_sleep.wait ]
}

resource "time_sleep" "wait" {
  create_duration = "20s"
  depends_on = [
    var.cross_account_role_arn
  ]
}

resource "databricks_mws_workspaces" "this" {
  account_id               = var.databricks_account_id
  aws_region               = var.aws_region
  workspace_name           = "WS_MVSH_${upper(var.environment)}"
  
  credentials_id           = databricks_mws_credentials.this.credentials_id
  network_id               = databricks_mws_networks.this.network_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id

  token {
    comment = "Terraform"
  }
}