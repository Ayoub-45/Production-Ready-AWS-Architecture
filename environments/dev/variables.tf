variable "project_name" {
  type        = string
  description = "Production-ready AWS infrastructre built to demonstrate high availability architecture."
  default     = "production-ready-aws-infrastructure"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in"
  default     = "us-east-1"
}
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
variable "availability_zones" {
  type        = list(string)
  description = "availability zones for our architecture"
  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"

  default = [
    "10.0.1.0/24",
    "10.0.4.0/24"
  ]
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private application subnets"

  default = [
    "10.0.2.0/24",
    "10.0.5.0/24"
  ]
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private database subnets"

  default = [
    "10.0.3.0/24",
    "10.0.6.0/24"
  ]
}
