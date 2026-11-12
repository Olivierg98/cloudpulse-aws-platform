# Deployment evidence checklist

Evidence is marked complete only when the linked execution or observation supports it. GitHub Actions run results verify workflow steps, but do not replace an AWS configuration review or long-running availability test.

## Verified by recorded development workflow

- [x] **GitHub Actions deployment completed through OIDC.** [Successful deployment run #7](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/35581600501), including the "Configure AWS credentials with GitHub OIDC" step.
- [x] **Application smoke test passed after deployment.** The same run completed the "Smoke test" step, which exercises the ALB-facing application endpoints including `/health`. This establishes a successful point-in-time check, not continuous availability.

## Not independently verified by this audit

- [ ] HTTPS certificate is valid and HTTP redirects to HTTPS in an AWS deployment
- [ ] Two healthy ALB targets were observed in separate Availability Zones (Terraform config alone is insufficient)
- [ ] EC2 security group / effective network reachability was independently checked in AWS (Terraform config specifies no inbound SSH)
- [ ] WAF web ACL was associated with the deployed ALB
- [ ] CloudWatch dashboard was observed with live traffic
- [ ] Alarm notification was received and recovered
- [ ] Instance termination drill restored desired capacity
- [ ] RDS is private and a restore was tested
- [ ] Monthly cost and teardown date were recorded

## Pull-request extensions

- [x] [Serverless PR #3](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/3): [GitHub Actions verification](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/43116117073) passed Lambda packaging, Terraform validation, mocked tests and an AWS development **plan only** (no apply)
- [ ] Serverless PR #3: real GitLab pipeline execution and live AWS deployment
- [x] [Kubernetes GitOps PR #5](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/5): [successful GitHub Actions run](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/43126957746) completed kind setup, Helm/Kustomize validation and Flux rollout/failure/recovery exercise; see [recovery evidence](GITOPS-RECOVERY-EVIDENCE.md)
- [ ] [Terraform review PR #4](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/4): production account isolation and required-review settings enforced
- [ ] [Azure starter PR #2](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/2): deployed and validated in Azure

Store redacted screenshots in `docs/evidence/`. Do not capture account IDs, email addresses, secrets or credentials. Update this checklist only when new reproducible evidence is available.
