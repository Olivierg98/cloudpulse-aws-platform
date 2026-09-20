# Incident runbook

## ALB returns 5xx

1. Confirm impact and timestamp with the ALB `HTTPCode_Target_5XX_Count` metric.
2. Check target health and the Auto Scaling activity history.
3. Query `/cloudpulse/<environment>/application` logs around the first failure.
4. Use Systems Manager Session Manager if host-level inspection is necessary; SSH is not exposed.
5. If the latest release caused the incident, roll back to the previous ECR digest.
6. Run the smoke test, confirm alarm recovery and record the timeline and root cause.

## Database unavailable

1. Check RDS events, storage, connections and CPU.
2. Verify the application-to-database security-group rule and secret version.
3. Avoid editing production data while diagnosing connectivity.
4. Restore to a new instance from the latest recovery point when corruption is confirmed.
5. Validate the restored endpoint before controlled cutover.

## Compromised workload suspected

1. Preserve CloudTrail, GuardDuty and application evidence.
2. Remove the instance from service by reducing desired capacity only after evidence is captured.
3. Rotate affected credentials and secret versions.
4. Replace the instance through the immutable launch template; do not repair it in place.
5. Document scope, containment, eradication and follow-up controls.
