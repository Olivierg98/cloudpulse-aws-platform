# CloudPulse - Highly Available AWS Web Platform

[![CI](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/ci.yml)
[![Security](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/security.yml/badge.svg)](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/security.yml)
[![Deploy AWS](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/deploy.yml/badge.svg)](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/workflows/deploy.yml)

A production-style cloud engineering portfolio project by **Olivier Gouna**. CloudPulse provisions a resilient AWS web platform with Terraform and runs a containerised FastAPI service behind an Application Load Balancer. The repository separates inexpensive development defaults from production controls that incur AWS charges.

## Skills demonstrated

| Area | Evidence in this repository |
|---|---|
| AWS architecture | VPC, two AZs, ALB, EC2 Auto Scaling, ECR, optional RDS and NAT |
| Infrastructure as Code | Reusable Terraform module, dev/prod composition and S3 state bootstrap |
| Linux and containers | Amazon Linux bootstrap, non-root Docker image and health checks |
| Security | No inbound SSH in the configured application security group, SSM, IMDSv2 and Trivy; optional WAF, GuardDuty and Secrets Manager |
| Reliability | Load-balancer health checks, desired-capacity recovery, rolling refresh and scaling policy |
| Operations | Dashboard, SNS alarm, smoke test, runbook and documented failure drills |
| CI/CD | GitHub OIDC, immutable ECR images, Terraform validation, deployment and security gate |
| Cost control | AWS Budget, explicit trade-offs, tagged resources and controlled teardown |

## Project status and supporting evidence

**Verified AWS development deployment:** [GitHub Actions run #7](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/35581600501) completed the OIDC, Terraform, ECR image build/push and application smoke-test steps successfully. This is an engineering portfolio, **not a production service with demonstrated customer traffic or an uptime SLA**.

| Component | What is evidenced | What is not claimed |
|---|---|---|
| Core AWS development platform | Successful AWS workflow run and application endpoint checks | Full production security controls or sustained availability |
| [Serverless + GitLab extension (PR #3)](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/3) | Lambda/API Gateway/S3/CloudFront Terraform and GitLab CI configuration; [successful verification and AWS plan run](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/43116117073) | Live GitLab pipeline execution or AWS serverless deployment (pending) |
| [Kubernetes GitOps lab (PR #5)](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/5) | kind, Helm, Kustomize and Flux; [successful rollout/failure/recovery workflow](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/43126957746) | Production Kubernetes/OpenShift operations |
| [Terraform review controls (PR #4)](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/4) | Mocked dev-plan test and documented isolation/approval design | Separate production AWS accounts or enforced approvals |
| [Azure Container Apps starter (PR #2)](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/2) | Azure Terraform and Azure DevOps pipeline starter | Provisioned or validated Azure deployment |

The extensions are shown in pull requests rather than assumed to be merged into `main`. See the [deployment evidence checklist](docs/EVIDENCE-CHECKLIST.md) and [recovery test evidence](docs/GITOPS-RECOVERY-EVIDENCE.md) for what was observed and what remains unverified.

### Environment networking distinction

In the low-cost **development** defaults, application instances use **public subnets** but accept application traffic only from the ALB security group and do not permit inbound SSH. Public-subnet placement is **not** equivalent to having private-only compute. The optional **production-oriented** design places application instances in private subnets when `use_private_subnets=true`, with NAT egress when configured. HTTPS, WAF, private database and other production controls are optional and are not asserted to have been deployed together.

## Deployed development architecture

The development environment has been deployed and verified in `eu-west-2`. It uses the same reusable platform module as production, with expensive production-only controls disabled.

```mermaid
flowchart TB
  GH["GitHub Actions"] --> OIDC["AWS OIDC and IAM"]
  OIDC --> ECR["ECR immutable image"]
  OIDC --> TF["Terraform"]
  TF --> ALB["Application Load Balancer"]
  TF --> ASG["EC2 Auto Scaling"]
  ECR --> ASG
  ALB --> ASG
  ASG --> CW["CloudWatch"]
```

### Deployment flow

1. A manual GitHub Actions workflow starts the release.
2. GitHub authenticates to AWS through OIDC and assumes a short-lived IAM role; no permanent AWS access keys are stored in GitHub.
3. Terraform initialises against remote S3 state and ensures the ECR repository exists.
4. GitHub builds the non-root FastAPI Docker image and pushes it to ECR using the unique immutable tag `<commit-sha>-<run-id>-<run-attempt>`.
5. The workflow resolves the image digest and passes that exact image reference to Terraform.
6. Terraform creates or updates the VPC, subnets, load balancer, launch template, Auto Scaling group, IAM and monitoring resources.
7. EC2 pulls and starts the container. The Application Load Balancer exposes the service and performs health checks.
8. Automated smoke tests call the live health, instance and database-status endpoints before the deployment is marked successful.

## Target production architecture

The production configuration extends the verified development platform with HTTPS, WAF, NAT, encrypted RDS, Secrets Manager, GuardDuty and additional operational controls. These resources are optional because they incur additional AWS charges.

```mermaid
flowchart TB
  U[User] --> WAF[WAF and HTTPS ALB]
  WAF --> A[EC2 container / private AZ-a]
  WAF --> B[EC2 container / private AZ-b]
  A --> DB[(Encrypted RDS)]
  B --> DB
  GH[GitHub Actions OIDC] --> ECR[ECR immutable image]
  ECR --> A
  ECR --> B
  A --> CW[CloudWatch and SNS]
  B --> CW
```

See [the detailed architecture](docs/ARCHITECTURE.md), [deployment guide](docs/DEPLOYMENT.md), [incident runbook](docs/INCIDENT-RUNBOOK.md), [threat model](docs/THREAT-MODEL.md), [failure drills](docs/FAILURE-DRILLS.md), and [engineering trade-offs](docs/TRADEOFFS.md).

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
terraform -chdir=infra/environments/prod init -backend=false
terraform -chdir=infra/environments/prod validate
```

## Deploy to AWS

The recommended release path is the manual **Deploy AWS** GitHub Actions workflow. It uses OIDC for temporary AWS credentials and deploys a uniquely tagged, digest-pinned container image.

For local administration, prerequisites are AWS CLI credentials, Terraform 1.7+, and an AWS account with permission to create the documented resources. Start with development; production enables chargeable NAT, RDS, WAF and security services.

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

For repeatable releases, follow the [deployment guide](docs/DEPLOYMENT.md). Production should use a protected GitHub environment with a required reviewer.

## Verified deployment evidence

[GitHub Actions run #7](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/35581600501) successfully deployed commit `3fc49e5` to the development environment in `eu-west-2`.

The run verified:

- GitHub-to-AWS authentication through OIDC.
- Terraform initialisation using remote state.
- An immutable Docker image built and pushed to ECR.
- Deployment by exact SHA-256 image digest.
- An in-place EC2 launch-template update through Terraform.
- A healthy response from `/health`.
- Runtime information from `/api/instance`.
- Expected `configured: false` status from `/api/database`, because RDS is disabled in the lower-cost development environment.

The [evidence checklist](docs/EVIDENCE-CHECKLIST.md) distinguishes implemented production controls from features tested in the development AWS account.

## Troubleshooting and lessons learned

### IAM permissions

OIDC authentication succeeded before Terraform had permission to perform every required IAM operation. Deployment failures exposed missing read and instance-profile tagging permissions. The GitHub Actions role was updated with narrowly scoped permissions, reinforcing the distinction between authentication (who the workflow is) and authorisation (what it may do).

### Immutable ECR tags

Initial retries reused the Git commit SHA as the Docker tag. Because ECR tag immutability was enabled, ECR correctly rejected attempts to overwrite that tag. The workflow now combines the commit SHA, GitHub run ID and run attempt, producing a unique and traceable tag for every deployment attempt, then deploys the resolved image digest.

### Architecture & Engineering Decisions

**Why EC2 + Auto Scaling instead of Lambda?**
CloudPulse runs as a containerised web application with predictable, continuously available compute requirements. EC2 provides greater control over the runtime environment, while Auto Scaling allows instances to be replaced or scaled without relying on a single server. Lambda would be better suited to short-lived, event-driven workloads.

**Why private application subnets in the production-oriented design?**
The default low-cost development environment uses public subnets, with application traffic restricted by security groups to the ALB and no inbound SSH. The optional private-subnet configuration removes direct internet-facing addresses from application instances; traffic enters through the ALB. NAT or suitable endpoints must be provided for required outbound access.

**Why an Application Load Balancer?**
The ALB provides a single public entry point and distributes traffic across healthy application instances in multiple Availability Zones. Health checks stop traffic being sent to unhealthy targets and work with Auto Scaling to improve availability.

**Why GitHub OIDC instead of AWS access keys?**
GitHub Actions authenticates to AWS using OpenID Connect (OIDC), allowing the workflow to assume a short-lived IAM role for each deployment. This avoids storing long-lived AWS access keys in GitHub and reduces credential-management and leakage risk.

**Why immutable ECR image tags?**
ECR tag immutability prevents an existing container tag from being overwritten, making releases easier to trace and reproduce. When a retry attempted to reuse an existing immutable tag, the deployment failed as designed. The workflow was updated so each deployment attempt receives a unique tag while Terraform deploys the resolved image digest.

**Why two Availability Zones?**
CloudPulse distributes networking and compute across two Availability Zones so the application is not dependent on a single AZ. The ALB can route traffic to healthy instances across both zones, while Auto Scaling can replace unhealthy capacity.

### Infrastructure readiness

An early smoke test reached the load balancer before EC2 had finished installing Docker, pulling the image and passing target health checks, which produced a temporary `502`. The smoke test was changed to tolerate transient startup failures and retry for up to approximately five minutes. The subsequent deployment passed all live endpoint checks.

## Walkthrough

ALB is the controlled application ingress path; the configured application security group has no inbound SSH. Development instances use public subnets by default, while private-subnet placement is an optional production-oriented setting.

Auto Scaling provides replacement of unhealthy instances across Availability Zones.

Terraform modules separate reusable infrastructure from environment configuration.

CloudWatch monitoring and failure drills provide operational validation.

Cost, security and resilience trade-offs are documented alongside clear evidence of what has been verified in development and what is reserved for production.
