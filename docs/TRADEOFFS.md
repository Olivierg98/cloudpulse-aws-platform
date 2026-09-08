# Engineering trade-offs

- **Default cost versus network isolation:** the module defines private subnets but places the demo ASG in public subnets without public ingress. This avoids roughly £50+/month for two NAT Gateways. Production would run instances in private subnets with one NAT per AZ or VPC endpoints for ECR, SSM and CloudWatch.
- **HTTP versus TLS:** HTTP keeps the repository deployable without owning a domain. Production adds Route 53, an ACM certificate and an HTTPS listener that redirects port 80.
- **Local Terraform state:** safe for a single-person demo. Team use requires encrypted S3 state with locking and tightly controlled IAM.
- **Demo image:** bootstrap currently uses a public image so infrastructure can be tested independently. The release extension pushes CloudPulse to ECR and injects the immutable digest into the launch template.
