locals {
  iam_role_name  = "databricks-unity-catalog-metastore-access"
  iam_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_role_name}"
  metastore_name = var.metastore_name == null ? "metastore_uc_${replace(var.aws_region, "-", "_")}" : var.metastore_name
}

variable "tags" {
  description = "A map of tags to apply to the resources created by this module."
  type        = map(string)
}

variable "bucket_name" {
  description = "The name of the S3 bucket to be used for the Databricks metastore."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
}

variable "databricks_workspace_ids" {
  description = <<EOT
  List of Databricks workspace IDs to be enabled with Unity Catalog.
  Enter with square brackets and double quotes
  e.g. ["111111111", "222222222"]
  EOT
  type        = list(string)
  default     = []
}

variable "metastore_name" {
  description = "(Optional) Name of the metastore that will be created"
  type        = string
  default     = null
}