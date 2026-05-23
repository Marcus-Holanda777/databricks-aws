variable "aws_region" {
    description = "The AWS region where the resources will be created."
    type        = string
}

variable "profile_name" {
    description = "Name of the AWS profile to use."
    type        = string
}

variable "bucket_name" {
    description = "The name of the S3 bucket to create."
    type        = string
}

variable "databricks_account_id" {
    description = "Count ID databricks"
    type = string
}

variable "client_id" {
    description = "The client ID for the Databricks API."
    type = string
}

variable "client_secret" {
    description = "The client secret for the Databricks API."
    type = string
}

variable "email_admin" {
    description = "The email of the Databricks admin user."
    type = string
}

variable "group_members" {
    description = "A map of group names to lists of user emails."
    type = map(list(string))
}

variable "cidr_block" {
    description = "The CIDR block for the VPC."
    type        = string
}

variable "public_subnet_cidr_1" {
    description = "The CIDR block for the first public subnet."
    type        = string
}

variable "public_subnet_cidr_2" {
    description = "The CIDR block for the second public subnet."
    type        = string
}

variable "private_subnet_cidr_1" {
    description = "The CIDR block for the first private subnet."
    type        = string
}

variable "private_subnet_cidr_2" {
    description = "The CIDR block for the second private subnet."
    type        = string
}

variable "tags" {
    description = "A map of tags to apply to the resources."
    type        = map(string)
}