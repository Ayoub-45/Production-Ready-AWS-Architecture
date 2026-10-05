# Extra permissions for the apply role: RDS, ACM, the RDS-managed master secret,
# and attaching an inline policy to the project's EC2 role.
# Additive file: nothing in the existing bootstrap files changes.
# Apply it locally (cd bootstrap && terraform apply) BEFORE merging the RDS/HTTPS PR.

resource "aws_iam_role_policy_attachment" "apply_rds" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

data "aws_iam_policy_document" "apply_rds_acm" {
  statement {
    sid = "ManageAcmCertificates"
    actions = [
      "acm:RequestCertificate", "acm:DescribeCertificate", "acm:GetCertificate",
      "acm:DeleteCertificate", "acm:AddTagsToCertificate", "acm:RemoveTagsFromCertificate",
      "acm:ListTagsForCertificate",
    ]
    resources = ["*"]
  }

  # RDS creates and deletes the master-password secret on the caller's behalf.
  statement {
    sid = "RdsManagedMasterSecret"
    actions = [
      "secretsmanager:CreateSecret", "secretsmanager:TagResource",
      "secretsmanager:DescribeSecret", "secretsmanager:DeleteSecret",
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:rds!*"]
  }

  statement {
    sid       = "DescribeKmsKeyForManagedSecret"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid       = "ManageInlinePoliciesOnProjectRoles"
    actions   = ["iam:PutRolePolicy", "iam:DeleteRolePolicy"]
    resources = [local.role_arn]
  }

  statement {
    sid       = "CreateRdsServiceLinkedRoleOnFirstUse"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "apply_rds_acm" {
  name   = "rds-and-acm-permissions"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_rds_acm.json
}
