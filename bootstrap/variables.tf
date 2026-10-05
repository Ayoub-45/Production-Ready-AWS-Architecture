variable "aws_region" {
  type        = string
  description = "Region for the state bucket and IAM resources"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Must match project_name in environments/dev. IAM permissions for the apply role are scoped to this prefix."
  default     = "production-ready-aws-infrastructure"
}

variable "name_prefix" {
  type        = string
  description = "Short prefix for the state bucket (S3 names are limited to 63 chars)"
  default     = "prod-aws"
}

variable "github_org" {
  type        = string
  description = "GitHub user or organization that owns the repo"
  default     = "Ayoub-45"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "Production-Ready-AWS-Architecture"
}

variable "github_environment" {
  type        = string
  description = "GitHub Environment (with required reviewers) that gates terraform apply"
  default     = "dev"
}

variable "state_key_prefix" {
  type        = string
  description = "Key prefix inside the state bucket that the CI roles may touch"
  default     = "dev/"
}
variable "github_owner_id" {
  type        = string
  description = "Numeric GitHub owner ID (appears in the OIDC sub claim)"
  default     = "81306696"
}

variable "github_repo_id" {
  type        = string
  description = "Numeric GitHub repository ID (appears in the OIDC sub claim)"
  default     = "1389360527"
}
