# Engineering trade-offs

- **Default cost versus network isolation:** development can place instances in public subnets with no inbound route except the ALB. Production uses private subnets and one NAT gateway. One NAT lowers portfolio cost but is a single-AZ egress dependency; a larger production system uses one per AZ or private VPC endpoints.
- **HTTP versus TLS:** development remains deployable without a domain. Providing an ACM certificate enables HTTPS and redirects HTTP. Route 53 remains account/domain-specific instead of being fabricated in reusable code.
- **Terraform state:** `infra/bootstrap` creates an encrypted, versioned and publicly blocked S3 bucket. Example backends use native S3 lockfiles. Bootstrap state must be protected separately.
- **Database availability versus cost:** RDS is encrypted and backup-enabled. Multi-AZ is configurable but disabled in the portfolio production defaults until the live cost is explicitly approved.
- **Immutable delivery:** the deployment workflow first creates ECR, then pushes the commit image and reapplies Terraform using its digest. The two-phase first deployment is more verbose but avoids maintaining a second repository stack.
- **Account-level security:** GuardDuty is optional because enabling an account-level detector may conflict with centrally managed security accounts.
