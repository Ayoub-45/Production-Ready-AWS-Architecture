output "db_endpoint" {
  description = "Hostname of the database (resolves to the current primary, also after a failover)"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database listens on"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}

output "db_security_group_id" {
  description = "Security group ID of the database"
  value       = aws_security_group.db.id
}

output "db_instance_id" {
  description = "Identifier of the DB instance (used for failover tests and alarms)"
  value       = aws_db_instance.this.identifier
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the master credentials"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
