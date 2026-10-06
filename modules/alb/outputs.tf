output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.app.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app.arn
}

output "cloudflare_zone_id" {
  description = "Cloudflare hosted zone ID of the ALB"
  value       = aws_lb.app.zone_id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate (empty when domain_name is not set)"
  value       = one(aws_acm_certificate.app[*].arn)
}

# ACM  validation record
output "acm_validation_records" {
  description = "DNS records to create at your DNS provider to validate the ACM certificate"
  value = var.domain_name == "" ? [] : [
    for o in aws_acm_certificate.app[0].domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ]
}
