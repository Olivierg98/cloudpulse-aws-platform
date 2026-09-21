#!/usr/bin/env bash
set -euo pipefail
base_url="${1:-http://localhost:8000}"
curl --fail --retry 60 --retry-delay 5 --retry-all-errors "${base_url}/health"
curl --fail "${base_url}/api/instance"
curl --fail "${base_url}/api/database"
