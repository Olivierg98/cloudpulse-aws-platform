# CloudPulse — Highly Available AWS Web Platform

[![CI](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/ci.yml)
[![Security](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/security.yml/badge.svg)](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/security.yml)

A production-style cloud engineering portfolio project by **Olivier Gouna**. CloudPulse provisions a resilient AWS web platform with Terraform and runs a containerised FastAPI service behind an Application Load Balancer.

## Skills demonstrated

| Area | Evidence in this repository |
|---|---|
| AWS architecture | VPC, two AZs, ALB, EC2 Auto Scaling, IAM and CloudWatch |
| Infrastructure as Code | Reusable Terraform module, validated variables and environment composition |
| Linux and containers | Amazon Linux bootstrap, non-root Docker image and health checks |
| Security | No inbound SSH, SSM role, IMDSv2, scoped security groups and Trivy scanning |
| Reliability | Load-balancer health checks, desired-capacity recovery, rolling refresh and scaling policy |
| Operations | Dashboard, unhealthy-target alarm, smoke test and documented failure drills |
| CI/CD | GitHub Actions tests, image build, Terraform validation and security gate |
| Cost control | Explicit trade-offs, tagged resources and one-command teardown |

## Architecture

```mermaid
flowchart LR
  U[User] --> ALB[Application Load Balancer]
  subgraph VPC[AWS VPC / two AZs]
    ALB --> EC2A[EC2 container / AZ-a]
    ALB --> EC2B[EC2 container / AZ-b]
    ASG[Auto Scaling] --> EC2A
    ASG --> EC2B
  end
  EC2A --> CW[CloudWatch]
  EC2B --> CW
```

See [the detailed architecture](docs/ARCHITECTURE.md), [failure drills](docs/FAILURE-DRILLS.md), and [engineering trade-offs](docs/TRADEOFFS.md).

## Run locally

```bash
git clone https://github.com/Olivierg98/cloudpulse-aws-platform.git
cd cloudpulse-aws-platform
docker compose up --build
curl http://localhost:8000/health
```

Open `http://localhost:8000` to view the runtime dashboard.

## Test and validate

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest -q
terraform fmt -check -recursive infra
terraform -chdir=infra/environments/dev init -backend=false
terraform -chdir=infra/environments/dev validate
```

## Deploy to AWS

Prerequisites: AWS CLI credentials, Terraform 1.7+, and an AWS account with permission to create the documented resources.

```bash
cd infra/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output application_url
```

Run the [smoke test](scripts/smoke-test.sh) against the output URL. AWS resources incur charges. Destroy them after collecting evidence:

```bash
terraform destroy
```

## Interview walkthrough

1. Explain why the ALB is the only ingress path and why SSH is absent.
2. Show how Auto Scaling replaces an unhealthy instance across availability zones.
3. Walk through the Terraform module boundary and CI quality gates.
4. Demonstrate a failure drill using CloudWatch evidence.
5. Explain the documented cost/security trade-offs and production extensions.

## Roadmap

- Publish the application image to Amazon ECR with immutable tags.
- Add OIDC-based GitHub-to-AWS deployment without long-lived access keys.
- Move compute fully private using VPC endpoints or per-AZ NAT Gateways.
- Add Route 53, ACM TLS and AWS WAF.
- Add remote encrypted Terraform state and policy checks.

> The default AWS bootstrap uses a minimal Nginx health service so the infrastructure can be tested before a registry exists. The full FastAPI image runs locally; publishing it to ECR is the next release milestone. Availability and performance claims should be backed by captured failure-drill evidence after deployment.
