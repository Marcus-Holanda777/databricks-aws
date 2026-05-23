resource "aws_iam_role" "cross_account_role" {
  name               = "databricks-cross-account-role-${var.environment}"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json

  tags = merge(
    {
      Name        = "mvsh-databricks-cross-account-role-${var.environment}"
      Environment = var.environment
      Component   = "IAM-Lakehouse"
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "this" {
  name   = "databricks-cross-account-policy-${var.environment}"
  role   = aws_iam_role.cross_account_role.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

resource "aws_iam_role" "unity_catalog_role" {
  name               = "databricks-unity-catalog-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.unity_catalog_trust_policy.json

  tags = merge(
    {
      Name        = "mvsh-databricks-unity-catalog-role-${var.environment}"
      Environment = var.environment
      Component   = "IAM-Lakehouse"
    },
    var.tags
  )
}

resource "aws_iam_policy" "unity_catalog_s3_policy" {
  name   = "databricks-unity-catalog-s3-policy-${var.environment}"
  policy = data.aws_iam_policy_document.unity_catalog_s3_policy_doc.json

  tags = merge(
    {
      Name        = "mvsh-databricks-unity-catalog-s3-policy-${var.environment}"
      Environment = var.environment
      Component   = "IAM-Lakehouse"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "unity_catalog_attach" {
  role       = aws_iam_role.unity_catalog_role.name
  policy_arn = aws_iam_policy.unity_catalog_s3_policy.arn
}