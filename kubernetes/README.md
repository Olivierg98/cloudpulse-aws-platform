# CloudPulse Kubernetes GitOps lab

Deploys the existing FastAPI image to a disposable kind cluster. Helm packages a
Deployment and ClusterIP Service. A Kustomize overlay sets the dev replica count
and image tag. Flux reads the Git revision, applies the overlay and manages the
Helm release. The lab uses locally loaded images and requires no AWS resources or
registry credentials.

## Rollout and recovery

1. Reconcile the baseline revision and verify two ready pods and an HTTP success
   from the Service's /health endpoint.
2. Reconcile a Git revision that changes the desired image tag from v1 to v2.
   Verify both replicas and the same health check.
3. Reconcile a revision referencing an unavailable local image. Verify the
   Kubernetes image error and the failed Helm release.
4. Reconcile a recovery commit that restores v2. Verify both replicas and the
   Service again.

The harness pins and selects individual Git revisions so all stages can be
replayed in one run. The v1 and v2 builds use the same app source with different
image metadata so the lab isolates rollout behaviour from application changes.

## Run locally

Install Docker, kind, kubectl, Helm and Flux. From the repository root:

```sh
kind create cluster --name cloudpulse
docker build --label org.opencontainers.image.version=v1 -t cloudpulse:v1 .
docker build --label org.opencontainers.image.version=v2 -t cloudpulse:v2 .
kind load docker-image --name cloudpulse cloudpulse:v1 cloudpulse:v2
bash kubernetes/demo.sh \
  1ac65fe1afe72e041a9720e41e0bc7dbba6e6e3d \
  d5505fbf0d1415779c13cf3a02122cd32c015ed7 \
  1ae423e6a203f749cdb9cfb5c86d643082c23df2 \
  5aebba83533b0601825d90db58df7ca583c8b66d
kind delete cluster --name cloudpulse
```

Use a fresh cluster for each run. GitHub Actions runs the same lab on a temporary
runner and reports the observed results in the job summary.
