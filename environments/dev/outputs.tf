output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = module.network.db_subnet_ids
}

output "app_security_group_id" {
  description = "Security group ID for application instances"
  value       = module.compute.app_security_group_id
}

output "asg_name" {
  description = "Application Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "launch_template_id" {
  description = "Application Launch Template ID"
  value       = module.compute.launch_template_id
}
