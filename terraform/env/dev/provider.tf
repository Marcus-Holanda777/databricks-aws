terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  profile = var.profile_name
}

provider "databricks" {
  alias         = "mws"
  host          = "https://accounts.cloud.databricks.com"
  account_id    = var.databricks_account_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

provider "databricks" {
  alias         = "workspace"
  host          = module.databricks_workspace.workspace_url
  client_id     = var.client_id
  client_secret = var.client_secret
}