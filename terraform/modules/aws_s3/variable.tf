variable "bucket_name" {
    description = "The name of the S3 bucket to create."
    type        = string
}

variable "environment" {
    description = "The environment for the S3 bucket (e.g., dev, staging, prod)."
    type        = string
}

variable "tags" {
    description = "Additional tags for the S3 bucket."
    type        = map(string)
}

variable "aws_region" {
    description = "The AWS region for the S3 bucket."
    type        = string
}

variable "subfolders" {
    description = "List of subfolders to create within the S3 bucket."
    type        = list(string)
    default     = []
}