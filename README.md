# Production-Ready AWS Architecture

A Terraform-managed AWS application platform built around a multi-AZ network, private EC2 application tier, Application Load Balancer, PostgreSQL on Amazon RDS, and an approval-gated GitHub Actions deployment workflow.

This repository is a hands-on infrastructure engineering project. It documents how the AWS resources fit together, how traffic reaches the application, and how infrastructure changes are planned and applied.

> **Deployment note:** The configuration currently deploys a development environment with production-oriented patterns. It should not be interpreted as a fully production-hardened service yet. In particular, the RDS instance is currently single-AZ and automated backup retention defaults to zero. See [Known limitations and next steps](#known-limitations-and-next-steps).

## Architecture

The infrastructure is deployed in **US East (N. Virginia), `us-east-1`**, across two Availability Zones.

### Request path

1. A user requests `https://app.ayoub-devops.com`.
2. Cloudflare DNS resolves the application hostname to the public Application Load Balancer.
3. The ALB terminates TLS using an AWS Certificate Manager certificate. HTTP requests are redirected to HTTPS when HTTPS is enabled.
4. The ALB forwards traffic to healthy EC2 instances registered in its target group.
5. EC2 instances run in private application subnets and are managed by an Auto Scaling Group.
6. The application tier connects to PostgreSQL in private database subnets. The database security group accepts PostgreSQL traffic only from the application security group.

### Network layout

| Tier | Availability Zone A | Availability Zone B | Purpose |
|---|---|---|---|
| Public | `10.0.1.0/24` | `10.0.4.0/24` | Internet-facing ALB and NAT Gateways |
| Private application | `10.0.2.0/24` | `10.0.5.0/24` | EC2 Auto Scaling Group |
| Private database | `10.0.3.0/24` | `10.0.6.0/24` | RDS subnet group |

The VPC CIDR is `10.0.0.0/16`. Each application subnet has a route through its **same-AZ NAT Gateway** for outbound internet access. Database subnets use private route tables and do not receive a default internet route.

For the complete component and traffic-flow diagram, see [docs/architecture.md](docs/architecture.md).

## AWS components

| Component | Implementation |
|---|---|
| Networking | VPC, two public subnets, two private application subnets, two private database subnets, Internet Gateway, route tables, and one NAT Gateway per AZ |
| Load balancing | Internet-facing Application Load Balancer and target group |
| TLS and DNS | ACM DNS validation records managed through Cloudflare; Cloudflare CNAME for the application hostname |
| Compute | Amazon Linux 2023 EC2 instances in an Auto Scaling Group |
| Scaling and health | Desired capacity 2, minimum 2, maximum 4; ELB health checks and rolling instance refresh |
| Instance access | IAM instance profile with AWS Systems Manager Session Manager permissions; no SSH access path is configured |
| Instance metadata | IMDSv2 required by the launch template |
| Database | Private Amazon RDS for PostgreSQL, encrypted gp3 storage, generated master credentials managed by RDS/Secrets Manager |
| Database access | PostgreSQL ingress restricted to the application security group; PostgreSQL SSL enforced through the parameter group |
| Database operations | PostgreSQL and upgrade log exports to CloudWatch; deletion protection enabled by default |
| Terraform state | Encrypted S3 backend with versioning and Terraform's native S3 state lock file |
| CI/CD identity | GitHub Actions authenticates to AWS through GitHub OIDC roles rather than long-lived AWS access keys |

## Infrastructure as Code

Terraform is split into reusable modules and an environment root module.

```text
.
├── bootstrap/
│   ├── main.tf                 # Remote state bucket and GitHub OIDC roles
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── environments/
│   └── dev/
│       ├── main.tf             # Composes the infrastructure modules
│       ├── network.tf          # Network module configuration
│       ├── database.tf         # RDS module and secret-read policy
│       ├── backend.tf          # S3 remote state configuration
│       ├── provider.tf
│       ├── versions.tf
│       ├── variables.tf
│       └── outputs.tf
├── modules/
│   ├── network/
│   ├── compute/
│   ├── alb/
│   └── database/
└── .github/
    └── workflows/
        └── terraform-apply.yml
```

### Module responsibilities

- **network** — VPC, public/application/database subnets, Internet Gateway, NAT Gateways, route tables, and subnet associations.
- **compute** — EC2 IAM role and instance profile, SSM permissions, security group, Amazon Linux 2023 launch template, and Auto Scaling Group.
- **alb** — ALB security group, internet-facing ALB, target group, listener rules, application ingress rule, ACM certificate validation, and Cloudflare DNS records.
- **database** — RDS subnet group, database security group, PostgreSQL parameter group, and RDS instance.

The `bootstrap/` stack is intentionally separate from the application environment. It provisions the Terraform state bucket and the AWS identity roles used by GitHub Actions.

## CI/CD workflow

The workflow in `.github/workflows/terraform-apply.yml` is triggered by changes under `environments/**` or `modules/**` on `main`, and can also be started manually.

The workflow follows this sequence:

1. GitHub Actions obtains short-lived AWS credentials using OIDC and the plan role.
2. Terraform initializes against the S3 backend and generates a saved plan.
3. The plan is written to the GitHub Actions job summary and uploaded as a short-lived artifact.
4. The apply job targets the GitHub Environment named `dev`. Configure required reviewers on this environment to enforce manual approval.
5. After approval, the workflow downloads and applies the **same saved plan** that was reviewed.

The workflow sets `cancel-in-progress: false` for the Terraform concurrency group so an active apply is not cancelled by a newer run.

### Required GitHub configuration

Configure the following repository variables:

| Variable | Purpose |
|---|---|
| `AWS_PLAN_ROLE_ARN` | ARN of the read-oriented OIDC role created by the bootstrap stack |
| `AWS_APPLY_ROLE_ARN` | ARN of the OIDC role used by the approval-gated apply job |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID for the application domain |

Configure this repository secret:

| Secret | Purpose |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token used by the Terraform provider |

Also create a GitHub Environment named `dev` and configure its required reviewers. The apply job references this environment.

> **IAM review required:** The current bootstrap apply role policy does not yet grant the RDS and Secrets Manager permissions required by the database module, and the Cloudflare provider also needs a valid API token with the necessary zone/DNS permissions. Review and extend the role's least-privilege policy before expecting the full environment to apply successfully from CI. Do not solve this by granting unrestricted administrator access.

## Getting started

### Prerequisites

- An AWS account and credentials permitted to create the bootstrap resources.
- Terraform **1.10 or later**.
- AWS CLI configured for the intended account.
- A Cloudflare zone for the application hostname.
- A GitHub repository with Actions enabled.

### 1. Bootstrap remote state and OIDC roles

The bootstrap stack uses local state initially. From the repository root:

```bash
cd bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Record the outputs:

- `state_bucket_name`
- `plan_role_arn`
- `apply_role_arn`

The state bucket is configured with versioning, server-side encryption, public-access blocking, a TLS-only bucket policy, and lifecycle cleanup for old non-current object versions. Terraform's S3-native lock file is used; a DynamoDB lock table is not required.

### 2. Configure the environment backend

Check `environments/dev/backend.tf` and ensure its bucket name matches the `state_bucket_name` output from bootstrap. The backend key is `dev/terraform.tfstate` in `us-east-1`.

### 3. Configure provider inputs

The environment expects a Cloudflare zone ID through the Terraform variable `cloudflare_zone_id`. For local execution, provide it through an untracked `terraform.tfvars` file or the `TF_VAR_cloudflare_zone_id` environment variable.

For example:

```bash
cd ../environments/dev
export CLOUDFLARE_API_TOKEN="your-cloudflare-api-token"
export TF_VAR_cloudflare_zone_id="your-cloudflare-zone-id"
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Do not commit API tokens, credentials, `.tfvars` files containing secrets, Terraform state, or saved plans.

### 4. Provision the environment

Review the Terraform plan carefully before applying:

```bash
terraform apply
```

The default environment configuration enables HTTPS and uses `app.ayoub-devops.com`. Make sure the domain, Cloudflare zone, ACM validation, and provider credentials are configured for your own deployment before applying.

### 5. Inspect Terraform outputs

Useful outputs include:

- `vpc_id`
- `app_subnet_ids`
- `db_subnet_ids`
- `app_security_group_id`
- `asg_name`
- `launch_template_id`
- `alb_dns_name`
- `target_group_arn`
- `domain_name`

### 6. Destroy resources safely

The RDS instance has deletion protection enabled by default and final snapshots are not skipped by default. To destroy the environment, first review the data-retention requirements, then explicitly disable deletion protection through Terraform and apply that change. Only then proceed with a reviewed destroy operation.

## Security design

- Application and database instances are not assigned public IP addresses.
- The ALB is the public entry point; application ingress is allowed from the ALB security group rather than a broad internet CIDR.
- The database accepts PostgreSQL connections only from the application security group.
- Database storage is encrypted, and the PostgreSQL parameter group enforces SSL connections.
- RDS generates and manages the master password in Secrets Manager. The application EC2 role receives a resource-scoped policy for reading the database secret.
- EC2 uses an instance profile and Systems Manager permissions instead of an SSH key/bastion access pattern.
- IMDSv2 is required on EC2 instances.
- GitHub Actions uses OIDC federation and short-lived role credentials instead of static AWS keys.
- Terraform state is stored in an encrypted, versioned, private S3 bucket with native state locking.

## Known limitations and next steps

This repository is a working infrastructure build and an evolving reference architecture. The following items should be addressed before describing it as production-ready:

1. **RDS high availability:** The RDS instance currently sets `multi_az = false`. The database subnet group spans two AZs, but that alone does not provide a Multi-AZ standby.
2. **Database backups:** The current default for `backup_retention_days` is `0`. Set an appropriate retention period and test restore procedures.
3. **CI apply permissions:** Extend the bootstrap apply role with narrowly scoped RDS and Secrets Manager permissions needed by the database resources. Validate the Cloudflare API token permissions separately.
4. **Application deployment:** The current EC2 user data installs Nginx and serves a hostname-based hello page. Add a versioned application deployment process, immutable artifacts, and rollback strategy.
5. **Observability:** Add application metrics, actionable alarms, dashboards, and alert routing. RDS log exports are already configured.
6. **Edge protection:** Consider AWS WAF, rate limiting, and a documented Cloudflare proxy/security policy.
7. **Cost controls:** Two NAT Gateways improve AZ-level network resilience but have ongoing hourly and data-processing costs. Review NAT and RDS costs for non-production environments.
8. **Validation:** Add automated Terraform formatting, validation, linting, and security scanning as a separate pull-request workflow.

## Design goals

- **Availability:** Spread public and application resources across two Availability Zones and avoid cross-AZ NAT dependencies for application egress.
- **Isolation:** Keep application and database resources in private subnets.
- **Least privilege:** Express service-to-service access through security-group references and resource-scoped IAM policies.
- **Repeatability:** Provision infrastructure through reusable Terraform modules.
- **Safe delivery:** Review a saved Terraform plan and require approval before applying it.
- **Operational clarity:** Keep networking, compute, load balancing, database, and bootstrap concerns separated.

## License

No license is currently documented in this repository. If you intend others to reuse or distribute this project, add an explicit license.
