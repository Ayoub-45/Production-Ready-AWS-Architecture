# Bootstrap

Creates, once, with **local** state:
- S3 bucket for Terraform remote state (versioned, encrypted, private, TLS-only)
- GitHub OIDC provider
- `prod-aws-github-plan`  - assumable from PRs and `main`, read-only
- `prod-aws-github-apply` - assumable only from the `dev` GitHub Environment (approval gate)

    cd bootstrap
    terraform init
    terraform apply
    terraform output
