variable "project_name" {
  type        = string
  description = "Project name used as a prefix for resource names"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, digits, and hyphens."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB will be deployed"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs where the ALB will be deployed"

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnets are required for ALB high availability."
  }
}

variable "app_security_group_id" {
  type        = string
  description = "Security group ID of the application instances"
}

variable "alb_port" {
  type        = number
  description = "HTTP port exposed by the ALB"
  default     = 80

  validation {
    condition     = var.alb_port >= 1 && var.alb_port <= 65535
    error_message = "alb_port must be between 1 and 65535."
  }
}

variable "https_port" {
  type        = number
  description = "HTTPS port exposed by the ALB"
  default     = 443

  validation {
    condition     = var.https_port >= 1 && var.https_port <= 65535
    error_message = "https_port must be between 1 and 65535."
  }
}

variable "app_port" {
  type        = number
  description = "Port exposed by the application instances"
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "asg_name" {
  type        = string
  description = "Name of the application Auto Scaling Group"
}

variable "domain_name" {
  type        = string
  description = "Fully qualified domain name for the ACM certificate, for example app.example.com"
  default     = "app.ayoub-devops.com"
}

variable "enable_https" {
  type        = bool
  description = "Create the HTTPS listener and redirect HTTP traffic to HTTPS"
  default     = false
}

variable "ssl_policy" {
  type        = string
  description = "TLS security policy used by the HTTPS listener"
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for the domain"

  validation {
    condition     = trimspace(var.cloudflare_zone_id) != ""
    error_message = "cloudflare_zone_id must not be empty."
  }
}
