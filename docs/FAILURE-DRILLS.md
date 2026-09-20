# Failure drills

Record evidence from each drill in a GitHub issue or `docs/evidence/` screenshot.

1. **Instance loss:** terminate one instance. Confirm the ALB stays available and the ASG restores desired capacity.
2. **Application failure:** stop the container through SSM. Confirm the target becomes unhealthy and is replaced.
3. **CPU scaling:** generate load, observe the target-tracking alarm and confirm scale-out/scale-in.
4. **Bad release:** deploy a broken health endpoint, watch the rolling refresh pause, then revert the commit.
5. **Security check:** verify port 22 is unreachable and Session Manager access succeeds.
6. **Database restore:** restore the latest recovery point to a new identifier and validate it without modifying production.
7. **Alarm path:** force one safe threshold breach, confirm SNS delivery, recover the service and record both timestamps.
8. **Credential check:** verify the GitHub deployment used OIDC and that no long-lived AWS key exists in repository secrets.

For every drill capture hypothesis, command, CloudWatch evidence, outcome and remediation.
