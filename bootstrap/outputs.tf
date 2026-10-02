output "state_bucket_name" {
  description = "Put this in environments/dev/backend.tf"
  value       = aws_s3_bucket.state.bucket
}

output "plan_role_arn" {
  description = "GitHub repo variable AWS_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "GitHub repo variable AWS_APPLY_ROLE_ARN"
  value       = aws_iam_role.apply.arn
}
