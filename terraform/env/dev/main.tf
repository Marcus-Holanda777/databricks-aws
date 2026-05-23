module "network_dev" {
  source                = "../../modules/aws_vpc"

  aws_region            = var.aws_region
  environment           = "dev"
  cidr_block            = var.cidr_block
  public_subnet_cidr_1  = var.public_subnet_cidr_1
  public_subnet_cidr_2  = var.public_subnet_cidr_2
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2  
  multi_az_nat          = false
  tags                  = var.tags
}

module "s3_bronze" {
  source       = "../../modules/aws_s3"

  environment  = "dev"
  bucket_name  = "${var.bucket_name}-bronze"
  aws_region   = var.aws_region
  tags         = var.tags
}

module "s3_silver" {
  source       = "../../modules/aws_s3"

  environment  = "dev"
  bucket_name  = "${var.bucket_name}-silver"
  aws_region   = var.aws_region
  tags         = var.tags
}

module "s3_gold" {
  source       = "../../modules/aws_s3"

  environment  = "dev"
  bucket_name  = "${var.bucket_name}-gold"
  aws_region   = var.aws_region
  tags         = var.tags
}

module "s3_raw" {
  source       = "../../modules/aws_s3"

  environment  = "dev"
  bucket_name  = "${var.bucket_name}-raw"
  aws_region   = var.aws_region
  subfolders   = ["landing_zone"]
  tags         = var.tags
}

module "iam" {
  source                = "../../modules/aws_iam"

  environment           = "dev"
  databricks_account_id = var.databricks_account_id
  bucket_name           = var.bucket_name
  aws_region            = var.aws_region
  tags                  = var.tags  
}

module "databricks_workspace" {
  source                 = "../../modules/databricks_workspace"
  environment            = "dev"
  databricks_account_id  = var.databricks_account_id
  cross_account_role_arn = module.iam.cross_account_role_arn
  vpc_id                 = module.network_dev.vpc_id
  subnet_ids             = module.network_dev.private_subnet_ids
  security_group_id      = module.network_dev.security_group_id
  aws_region             = var.aws_region

  providers = {
    databricks = databricks.mws 
  }

  depends_on = [module.network_dev, module.iam]
}

module "databricks_users" {
  source       = "../../modules/databricks_users"
  environment  = "dev"
  email_admin  = var.email_admin
  workspace_id = module.databricks_workspace.workspace_id
  group_members = var.group_members

  providers = {
    databricks = databricks.mws
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [module.iam]

  create_duration = "30s"
}

module "databricks_data_gov" {
  source                 = "../../modules/databricks_data_gov"
  environment            = "dev"
  unity_catalog_role_arn = module.iam.unity_catalog_role_arn
  
  bucket_bronze_id      = module.s3_bronze.bucket_id
  bucket_silver_id      = module.s3_silver.bucket_id
  bucket_gold_id        = module.s3_gold.bucket_id
  bucket_raw_id         = module.s3_raw.bucket_id
  
  admin_group_name       = module.databricks_users.admin_group_name
  user_group_name        = module.databricks_users.user_group_name

  providers = {
    databricks = databricks.workspace
  }

  depends_on = [
    time_sleep.wait_30_seconds,
    module.databricks_users
  ]
}

output "vpc_id" {
  value = module.network_dev.vpc_id
}

output "cross_account_role_arn" {
  value = module.iam.cross_account_role_arn
}

output "unity_catalog_role_arn" {
  value = module.iam.unity_catalog_role_arn
}

output "storage_credential_external_id" {
  value = module.iam.storage_credential_external_id
}

output "databricks_workspace" {
  value = module.databricks_workspace.workspace_url
}

output "databricks_workspace_id" {
  value = module.databricks_workspace.workspace_id
}