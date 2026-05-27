resource "aws_iam_role" "cross_account_role" {
  name               = "databricks-cross-account-role-${var.environment}"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json

  tags = merge(
    {
      Name        = "databricks-cross-account-role-${var.environment}"
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
      Name        = "databricks-unity-catalog-role-${var.environment}"
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
      Name        = "databricks-unity-catalog-s3-policy-${var.environment}"
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

resource "aws_iam_role" "databricks_glue_role" {
  name               = "databricks-glue-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.databricks_glue_trust_policy.json

  tags = merge(
    {
      Name        = "databricks-glue-role-${var.environment}",
      Environment = var.environment,
      Component   = "IAM-Glue-Access",
    },
    var.tags,
  )
}

resource "aws_iam_role_policy_attachment" "aws_glue_standard_attach" {
  role       = aws_iam_role.databricks_glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy" "iceberg_s3_policy" {
  name        = "databricks-iceberg-s3-policy-${var.environment}"
  description = "Acesso estrito de leitura ao S3 do Iceberg para o modulo do Glue"
  policy      = data.aws_iam_policy_document.iceberg_s3_readonly_policy.json

  tags = merge(
    {
      Name        = "databricks-iceberg-s3-policy-${var.environment}",
      Environment = var.environment,
      Component   = "IAM-Glue-Access",
    },
    var.tags,
  )
}

resource "aws_iam_role_policy_attachment" "iceberg_s3_attach" {
  role       = aws_iam_role.databricks_glue_role.name
  policy_arn = aws_iam_policy.iceberg_s3_policy.arn
}