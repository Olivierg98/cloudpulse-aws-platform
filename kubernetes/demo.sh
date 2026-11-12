#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: bash kubernetes/demo.sh BASELINE UPDATE BROKEN RECOVERY" >&2
  exit 2
fi

for revision in "$@"; do
  [[ "$revision" =~ ^[a-f0-9]{40}$ ]]
done

[[ "$(kubectl config current-context)" == "kind-cloudpulse" ]]

kubectl create namespace cloudpulse
flux install --components=source-controller,kustomize-controller,helm-controller
kubectl apply -f - <<YAML
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: cloudpulse
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/Olivierg98/cloudpulse-aws-platform.git
  ref:
    commit: $1
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cloudpulse
  namespace: flux-system
spec:
  interval: 1m
  path: ./kubernetes/environments/dev
  prune: true
  sourceRef:
    kind: GitRepository
    name: cloudpulse
YAML

reconcile_revision() {
  local revision="$1"
  kubectl -n flux-system patch gitrepository cloudpulse --type=merge \
    -p "{\"spec\":{\"ref\":{\"commit\":\"$revision\"}}}"
  flux reconcile source git cloudpulse --timeout=2m
  flux reconcile kustomization cloudpulse --timeout=2m
  local observed
  observed="$(kubectl -n flux-system get kustomization cloudpulse -o jsonpath='{.status.lastAppliedRevision}')"
  [[ "$observed" == *"$revision" ]]
}

wait_for_image() {
  local expected="$1"
  local image
  for attempt in {1..40}; do
    image="$(kubectl -n cloudpulse get deployment cloudpulse --ignore-not-found \
      -o jsonpath='{.spec.template.spec.containers[0].image}')"
    if [[ "$image" == "$expected" ]]; then
      return 0
    fi
    sleep 3
  done
  echo "Expected deployment image $expected, saw $image" >&2
  return 1
}

verify_service() (
  local expected="$1"
  wait_for_image "$expected"
  flux reconcile helmrelease cloudpulse --timeout=2m
  kubectl -n cloudpulse rollout status deployment/cloudpulse --timeout=90s
  test "$(kubectl -n cloudpulse get deployment cloudpulse -o jsonpath='{.status.readyReplicas}')" = 2
  kubectl -n cloudpulse port-forward service/cloudpulse 18000:80 > /tmp/cloudpulse-port-forward.log 2>&1 &
  forward_pid=$!
  trap 'kill "$forward_pid" 2>/dev/null || true' EXIT
  curl --fail --silent --show-error --retry 10 --retry-delay 1 --retry-connrefused \
    --max-time 5 http://127.0.0.1:18000/health > /dev/null
  printf 'Verified %s with 2 ready replicas and a healthy service.\n' "$expected" | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
)

reconcile_revision "$1"
verify_service cloudpulse:v1
reconcile_revision "$2"
verify_service cloudpulse:v2

reconcile_revision "$3"
wait_for_image cloudpulse:unavailable
kubectl -n cloudpulse wait --for=jsonpath='{.status.containerStatuses[0].state.waiting.reason}'=ErrImageNeverPull \
  pod -l app.kubernetes.io/instance=cloudpulse \
  --field-selector=status.phase=Pending --timeout=90s
kubectl -n flux-system wait --for=condition=Released=false helmrelease/cloudpulse --timeout=120s
printf 'Detected unavailable image and failed Helm release.\n' | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"

reconcile_revision "$4"
verify_service cloudpulse:v2
printf 'Recovered by reconciling a Git revision that restores the previous image.\n' | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
