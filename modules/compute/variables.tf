variable "project_name" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where compute resources will be deployed"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "Private application subnet IDs"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of application instances"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of application instances"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of application instances"
  default     = 4
}
