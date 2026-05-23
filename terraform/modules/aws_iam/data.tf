data "databricks_aws_assume_role_policy" "this" {
  external_id = var.databricks_account_id
}

data "databricks_aws_crossaccount_policy" "this" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "unity_catalog_s3_policy_doc" {
  statement {
    sid = "S3Access"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}-bronze-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::${var.bucket_name}-bronze-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}/*",
      "arn:aws:s3:::${var.bucket_name}-silver-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::${var.bucket_name}-silver-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}/*",
      "arn:aws:s3:::${var.bucket_name}-gold-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::${var.bucket_name}-gold-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}/*",
      "arn:aws:s3:::${var.bucket_name}-raw-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::${var.bucket_name}-raw-${var.environment}-${var.aws_region}-${data.aws_caller_identity.current.account_id}/*"
    ]
  }

  statement {
    sid       = "AllowSelfAssume"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/databricks-unity-catalog-role-${var.environment}"]
  }
}

data "aws_iam_policy_document" "unity_catalog_trust_policy" {
  statement {
    sid     = "UnityCatalogAssume"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }

  statement {
    sid     = "SelfAssume"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/databricks-unity-catalog-role-${var.environment}"]
    }
  }
}