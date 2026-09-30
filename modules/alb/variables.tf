variable "project_name" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB will be deployed"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}

variable "app_security_group_id" {
  type        = string
  description = "Security group ID of the application instances"
}

variable "alb_port" {
  type        = number
  description = "Port exposed by the ALB"
  default     = 80
}

variable "app_port" {
  type        = number
  description = "Port exposed by application instances"
  default     = 80
}
variable "asg_name" {
  type        = string
  description = "Application Auto Scaling Group name"
}
