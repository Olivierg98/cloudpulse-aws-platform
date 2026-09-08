#!/usr/bin/env bash
set -euo pipefail
base_url="${1:-http://localhost:8000}"
curl --fail --retry 5 --retry-delay 2 "${base_url}/health"
curl --fail "${base_url}/api/instance"
