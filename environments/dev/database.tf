module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  db_subnet_ids         = module.network.db_subnet_ids
  app_security_group_id = module.compute.app_security_group_id

  multi_az            = true
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot
}

# The application instances may read this one secret and nothing else in Secrets Manager.
# (The secret uses the AWS managed key aws/secretsmanager, so no separate KMS permission is needed.)
data "aws_iam_policy_document" "read_db_secret" {
  statement {
    sid       = "ReadDatabaseSecret"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [module.rds.master_user_secret_arn]
  }
}

resource "aws_iam_role_policy" "read_db_secret" {
  name   = "read-db-secret"
  role   = module.compute.ec2_role_name
  policy = data.aws_iam_policy_document.read_db_secret.json
}
