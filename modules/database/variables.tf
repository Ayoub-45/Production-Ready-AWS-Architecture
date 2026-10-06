variable "project_name" {
  type        = string
  description = "Project name, used as a prefix for resource names (lowercase letters, digits and hyphens)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the database security group is created"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Private database subnet IDs (at least two, in different AZs)"
}

variable "app_security_group_id" {
  type        = string
  description = "Security group ID of the application instances; the only source allowed to reach the database"
}

variable "db_name" {
  type        = string
  description = "Name of the initial database"
  default     = "appdb"
}

variable "master_username" {
  type        = string
  description = "Master username (the password is generated and managed by RDS in Secrets Manager)"
  default     = "dbadmin"
}

variable "engine_major_version" {
  type        = string
  description = "PostgreSQL major version, for example 17. RDS picks the latest minor and upgrades it automatically"
  default     = "17"
}

variable "instance_class" {
  type        = string
  description = "DB instance class"
  default     = "db.t4g.small"
}

variable "allocated_storage" {
  type        = number
  description = "Initial storage in GiB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Upper limit in GiB for storage autoscaling (must be greater than allocated_storage)"
  default     = 50
}

variable "multi_az" {
  type        = bool
  description = "Run a synchronous standby in a second AZ with automatic failover"
  default     = true
}

variable "backup_retention_days" {
  type        = number
  description = "Days to keep automated backups (point-in-time recovery window)"
  default     = 0
}

variable "deletion_protection" {
  type        = bool
  description = "Block deletion of the instance. Turn off with an apply before running terraform destroy"
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip the final snapshot on deletion. Keep false so a destroy cannot silently lose data"
  default     = false
}

variable "db_port" {
  type        = number
  description = "PostgreSQL port"
  default     = 5432
}
