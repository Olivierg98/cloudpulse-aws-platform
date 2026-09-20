# Threat model

| Threat | Primary control | Residual risk / follow-up |
|---|---|---|
| Direct access to compute | ALB-only ingress, no port 22, security-group references | Validate with external port scan after deployment |
| Web exploits and abusive requests | AWS managed WAF rules, TLS, health checks | Add rate-based rules from measured traffic |
| Stolen AWS credentials | GitHub OIDC and short-lived sessions | Constrain trust policy to repository and environment |
| Vulnerable image or dependency | Trivy gate and ECR scan-on-push | Patch and rebuild from pinned dependencies |
| Metadata credential theft | IMDSv2 required | Restrict instance-role permissions further as features settle |
| Database exposure | Private subnets, SG from application only, encryption | Enable Multi-AZ and test restore for production |
| Secret disclosure | Secrets Manager; no credentials in Git | Add rotation and application retrieval at runtime |
| Undetected compromise | GuardDuty, CloudWatch and operational runbook | Centralise logs in a separate security account at scale |
| Unexpected spend | AWS Budget and optional resources | Add service-specific anomaly detection |
