terraform {
  backend "s3" {
    # Replace with the `state_bucket_name` output from bootstrap/
    bucket       = "prod-aws-tfstate-102378190347"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3-native locking (Terraform >= 1.10), no DynamoDB needed
  }
}
