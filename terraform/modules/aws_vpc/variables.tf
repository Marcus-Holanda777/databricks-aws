variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "environment" {
  description = "The environment for the VPC (e.g., dev, staging, prod)."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the VPC."
  type        = map(string)
}

variable "aws_region" {
  description = "The AWS region where the VPC will be created."
  type        = string
}

variable "public_subnet_cidr_1" {
  description = "The CIDR block for the first public subnet."
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "The CIDR block for the second public subnet"
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

variable "multi_az_nat" {
  description = "Boolean to determine if multiple NAT gateways should be created for high availability across multiple availability zones."
  type        = bool
}