#!/bin/bash
set -euxo pipefail
dnf install -y docker
systemctl enable --now docker
mkdir -p /opt/cloudpulse
cat >/opt/cloudpulse/default.conf <<'NGINX'
server {
  listen 8000;
  location = /health {
    default_type application/json;
    return 200 '{"status":"healthy","source":"aws-bootstrap"}';
  }
  location / {
    default_type text/html;
    return 200 '<h1>CloudPulse</h1><p>Highly available AWS platform is healthy.</p>';
  }
}
NGINX
docker run -d --restart always --name cloudpulse -p 8000:8000 \
  -e ENVIRONMENT='${environment}' -e AWS_REGION='${region}' \
  -v /opt/cloudpulse/default.conf:/etc/nginx/conf.d/default.conf:ro \
  public.ecr.aws/docker/library/nginx:stable-alpine
