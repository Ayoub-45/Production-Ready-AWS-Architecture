

resource "aws_iam_policy" "ecr_management" {
  name        = "${var.name_prefix}-ecr-management"
  description = "Allow Terraform apply role to manage the application ECR repository"

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "ecr:CreateRepository"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "CreateECRRepository"
      },
      {
        "Action" : [
          "ecr:DescribeRepositories",
          "ecr:TagResource",
          "ecr:ListTagsForResource",
          "ecr:UntagResource",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:DeleteRepository"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:ecr:us-east-1:102378190347:repository/prod-ready-aws-api",
        "Sid" : "ManageApplicationECRRepository"
      }
    ],
    "Version" : "2012-10-17"
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
    Stack     = "bootstrap"
  }
}

resource "aws_iam_role_policy_attachment" "github_apply_ecr_management" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.ecr_management.arn
}
