# GitOps rollout and recovery evidence

## Scope

CloudPulse Kubernetes lab: **disposable kind cluster**, Helm-managed FastAPI application, Kustomize dev overlay and Flux GitOps reconciliation. This is a CI-run recovery exercise, **not an AWS EC2/Auto Scaling recovery drill or production Kubernetes incident**.

- Implementation: [Kubernetes GitOps pull request #5](https://github.com/Olivierg98/cloudpulse-aws-platform/pull/5)
- Verification: [GitHub Actions Kubernetes GitOps lab run #1](https://github.com/Olivierg98/cloudpulse-aws-platform/actions/runs/43126957746), conclusion **success**
- Tested head commit: `656f95085b300cd19186e58279a2ed9c5f1743b8`
- Run job: `reconcile`; successful steps include **Check the Helm chart and dev overlay**, **Build and load the two lab images**, **Exercise Flux rollout and recovery**.
- Test logic: [kubernetes/demo.sh](https://github.com/Olivierg98/cloudpulse-aws-platform/blob/feature/cloudpulse-flux-lab/kubernetes/demo.sh)

## Hypothesis

A broken image reference should be detected as a failed deployment; a subsequent Git revision restoring a known available image should return the service to health.

## Method recorded in the workflow

1. Create an ephemeral kind cluster; lint/render the Helm chart and Kustomize overlay.
2. Build and preload two local Docker images (`cloudpulse:v1` and `cloudpulse:v2`).
3. Reconcile Git baseline through Flux; verify two ready replicas and successful HTTP `/health`.
4. Reconcile the update to `v2`; verify two ready replicas and healthy `/health`.
5. Reconcile an intentionally unavailable image; require an image-pull error and an unhealthy Helm release condition.
6. Reconcile the recovery revision restoring `v2`; verify two ready replicas and healthy `/health`.

## Observed outcome

GitHub reports the **Exercise Flux rollout and recovery** step, as well as the overall CI job, completed successfully. The script explicitly checks the expected image, readiness, service health and failed-release condition. This supports an automated local-lab rollout/failure/recovery demonstration, without claiming a manual production outage or AWS instance-termination recovery.

## Reproduction

The lab lives on the **PR #5 branch** until merged. Follow its [README](https://github.com/Olivierg98/cloudpulse-aws-platform/blob/feature/cloudpulse-flux-lab/kubernetes/README.md) to install Docker, kind, kubectl, Helm and Flux, then invoke `kubernetes/demo.sh` with the four pinned Git revisions as documented. The same exercise runs in the PR's GitHub Actions workflow.

## Still outstanding

- AWS Auto Scaling instance termination and measured ALB availability
- CloudWatch metric/alarm screenshots and alert notification receipt
- Real GitLab CI execution and serverless `terraform apply`
- Production-grade Kubernetes reliability, backup and security validation

Do not mark these as completed based on the local kind test.
