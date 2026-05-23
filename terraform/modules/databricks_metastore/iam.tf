resource "aws_iam_policy" "unity_metastore" {
  name = "databricks-unity-catalog-metastore-access-iam-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "databricks-unity-catalog-metastore"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "${aws_s3_bucket.metastore.arn}",
          "${aws_s3_bucket.metastore.arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [local.iam_role_arn],
        "Effect" : "Allow"
      }
    ]
  })

   tags = merge(
    {
      Name        = "databricks-unity-catalog-metastore-access-iam-policy"
      Component   = "IAM Role for Databricks Unity Catalog Metastore Access"
    },
    var.tags
  )
}

resource "aws_iam_policy" "sample_data" {
  name = "databricks-unity-catalog-sample-data-access-iam-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "databricks-unity-catalog-sample-data"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "arn:aws:s3:::databricks-datasets-oregon/*",
          "arn:aws:s3:::databricks-datasets-oregon"

        ],
        "Effect" : "Allow"
      }
    ]
  })

  tags = merge(
    {
      Name        = "databricks-unity-catalog-sample-data-access-iam-policy"
      Component   = "Storage-Lakehouse-Sample-Data"
    },
    var.tags
  )
}

resource "aws_iam_role" "metastore_data_access" {
  name                = local.iam_role_name
  assume_role_policy  = data.aws_iam_policy_document.passrole_for_uc.json

  tags = merge(
    {
      Name        = "databricks-unity-catalog-metastore-access-iam-role"
      Component   = "IAM Role for Databricks Unity Catalog Metastore Access"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "attach_unity_metastore_policy" {
  role       = aws_iam_role.metastore_data_access.name
  policy_arn = aws_iam_policy.unity_metastore.arn
}

resource "aws_iam_role_policy_attachment" "attach_sample_data_policy" {
  role       = aws_iam_role.metastore_data_access.name
  policy_arn = aws_iam_policy.sample_data.arn
}

resource "time_sleep" "wait_role_creation" {
  depends_on      = [aws_iam_role.metastore_data_access]
  create_duration = "20s"
}