# Deployment evidence checklist

Do not mark an item complete until it has been observed in Olivier's AWS account.

- [ ] GitHub Actions deployment completed through OIDC
- [ ] Application responds through the ALB and `/health` passes
- [ ] HTTPS certificate is valid and HTTP redirects to HTTPS
- [ ] Two healthy targets are distributed across Availability Zones
- [ ] EC2 has no inbound SSH rule
- [ ] WAF web ACL is associated with the ALB
- [ ] CloudWatch dashboard contains live traffic
- [ ] Alarm notification was received and recovered
- [ ] Instance termination drill restored desired capacity
- [ ] RDS is private and a restore was tested
- [ ] Monthly cost and teardown date were recorded

Store redacted screenshots in `docs/evidence/`. Never capture account IDs, email addresses, secrets or credentials.
