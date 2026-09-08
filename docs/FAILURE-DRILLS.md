# Failure drills

Record evidence from each drill in a GitHub issue or `docs/evidence/` screenshot.

1. **Instance loss:** terminate one instance. Confirm the ALB stays available and the ASG restores desired capacity.
2. **Application failure:** stop the container through SSM. Confirm the target becomes unhealthy and is replaced.
3. **CPU scaling:** generate load, observe the target-tracking alarm and confirm scale-out/scale-in.
4. **Bad release:** deploy a broken health endpoint, watch the rolling refresh pause, then revert the commit.
5. **Security check:** verify port 22 is unreachable and Session Manager access succeeds.

For every drill capture hypothesis, command, CloudWatch evidence, outcome and remediation.
