
data "aws_iam_policy_document" "api_publish_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"

      values = [
        "repo:Ayoub-45@81306696/Node.JS-API@1410575594:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "api_publish" {
  name               = "${var.name_prefix}-github-api-publish"
  assume_role_policy = data.aws_iam_policy_document.api_publish_trust.json
  description        = "Allows only the API repository main-branch workflow to publish images to ECR"
}

data "aws_iam_policy_document" "api_ecr_push" {
  statement {
    sid       = "GetECRAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushImagesToApiRepository"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]

    resources = [
      "arn:aws:ecr:${var.aws_region}:102378190347:repository/prod-ready-aws-api"
    ]
  }
}

resource "aws_iam_role_policy" "api_ecr_push" {
  name   = "push-api-images-to-ecr"
  role   = aws_iam_role.api_publish.id
  policy = data.aws_iam_policy_document.api_ecr_push.json
}
