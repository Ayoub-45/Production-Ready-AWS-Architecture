# Architecture and traffic flows

This document describes the architecture implemented by the Terraform configuration. It distinguishes the resources that are deployed today from production improvements that remain future work.

## High-level architecture

```mermaid
flowchart TB
    U[Users / Browsers]
    CF[Cloudflare DNS and proxy<br/>app.ayoub-devops.com]
    subgraph AWS[AWS account · us-east-1]
      subgraph VPC[VPC · 10.0.0.0/16]
        IGW[Internet Gateway]
        subgraph AZA[Availability Zone A]
          PUBA[Public subnet<br/>10.0.1.0/24]
          NATA[NAT Gateway A]
          APPA[Private app subnet<br/>10.0.2.0/24]
          DBA[Private DB subnet<br/>10.0.3.0/24]
        end
        subgraph AZB[Availability Zone B]
          PUBB[Public subnet<br/>10.0.4.0/24]
          NATB[NAT Gateway B]
          APPB[Private app subnet<br/>10.0.5.0/24]
          DBB[Private DB subnet<br/>10.0.6.0/24]
        end
        ALB[Internet-facing Application<br/>Load Balancer · HTTPS]
        ASG[EC2 Auto Scaling Group<br/>Amazon Linux 2023 · Nginx]
        RDS[(Amazon RDS PostgreSQL<br/>private · encrypted)]
      end
      ACM[AWS Certificate Manager]
      SM[AWS Secrets Manager<br/>RDS-generated master credentials]
      SSM[AWS Systems Manager<br/>Session Manager]
    end
    U --> CF
    CF -->|DNS / proxied HTTPS| ALB
    ACM -. certificate .-> ALB
    ALB -->|HTTP to target group| ASG
    ASG -->|PostgreSQL · 5432| RDS
    ASG -->|Read scoped secret| SM
    ASG -. managed instance access .-> SSM
    APPA --> NATA
    APPB --> NATB
    NATA --> IGW
    NATB --> IGW
    PUBA --- ALB
    PUBB --- ALB
    DBA --- RDS
    DBB --- RDS
```

> **Database availability clarification:** The RDS subnet group contains private subnets in both AZs, but the current RDS resource explicitly sets `multi_az = false`. The diagram shows the subnet group boundary, not a Multi-AZ database deployment or standby.

## Traffic flow

### Inbound application traffic

1. The client resolves the application hostname through Cloudflare.
2. Cloudflare's proxied DNS record points to the ALB DNS name.
3. The ALB security group accepts inbound HTTP/HTTPS.
4. When HTTPS is enabled, the HTTP listener redirects requests to HTTPS. ACM provides the listener certificate.
5. The ALB target group forwards HTTP traffic to the EC2 instances on the application port.
6. The application security group allows that port only from the ALB security group.

### Application egress

Each private application subnet has its own route table and same-AZ NAT Gateway. Outbound requests from an application instance use its AZ-local NAT Gateway and then the Internet Gateway. This avoids routing normal application egress through a NAT Gateway in the other AZ.

### Database access

The RDS instance is not publicly accessible. Its security group allows TCP/5432 only from the application security group. The PostgreSQL parameter group sets `rds.force_ssl = 1`. RDS manages the generated master password in Secrets Manager; the EC2 role receives a policy scoped to the RDS secret ARN.

The database subnets are associated with private route tables and do not have a default route to the Internet Gateway or NAT Gateways.

## Infrastructure delivery flow

```mermaid
flowchart TD
    DEV[Developer changes Terraform]
    GIT[Push to GitHub main<br/>or manual workflow dispatch]
    OIDC[GitHub Actions OIDC<br/>assume plan role]
    INIT[Terraform init<br/>S3 remote state + native lock]
    PLAN[terraform plan<br/>saved tfplan artifact]
    REVIEW[Review plan in Actions summary]
    APPROVAL[GitHub Environment: dev<br/>required reviewer approval]
    APPLY[Apply the exact saved plan<br/>using apply OIDC role]
    AWS[Update AWS infrastructure]
    DEV --> GIT --> OIDC --> INIT --> PLAN --> REVIEW --> APPROVAL --> APPLY --> AWS
```

The workflow serializes runs with a Terraform concurrency group and does not cancel an active apply. The bootstrap stack creates the S3 state bucket and GitHub OIDC roles separately from the application infrastructure.

## Current capacity and configuration

| Area | Current configuration |
|---|---|
| Region | `us-east-1` |
| VPC | `10.0.0.0/16` |
| Availability Zones | Two |
| Public subnets | Two |
| Private application subnets | Two |
| Private database subnets | Two |
| NAT | Two, one per AZ |
| EC2 | Amazon Linux 2023, `t3.micro` |
| Auto Scaling | Min 2 · Desired 2 · Max 4 |
| Load balancer | Internet-facing ALB |
| TLS | ACM certificate, DNS validation through Cloudflare |
| Database | PostgreSQL 17, `db.t4g.micro`, 20 GiB gp3 with 50 GiB autoscaling ceiling |
| RDS Multi-AZ | Disabled |
| Automated backup retention | 0 days by default |
| Database deletion protection | Enabled by default |
| Instance access | Systems Manager; no SSH ingress rule |

## Important production gaps

- Enable RDS Multi-AZ where the availability objective requires it.
- Configure non-zero automated backup retention and regularly test point-in-time recovery.
- Complete least-privilege CI permissions for RDS and Secrets Manager operations; verify Cloudflare token scopes.
- Replace the demonstration Nginx user-data page with a versioned application release and rollback mechanism.
- Add application-level telemetry, alarms, dashboards, and notification routing.
- Consider WAF/rate limiting and document the intended Cloudflare-to-ALB trust boundary.
