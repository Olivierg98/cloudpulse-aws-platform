#!/bin/bash
set -euxo pipefail
dnf install -y docker
systemctl enable --now docker
aws ecr get-login-password --region '${region}' | docker login --username AWS --password-stdin '${registry}' || true
docker pull '${app_image}'
docker run -d --restart always --name cloudpulse -p 8000:8000 \
  -e ENVIRONMENT='${environment}' -e AWS_REGION='${region}' \
  -e APP_VERSION='${app_version}' \
  -e DATABASE_SECRET_ARN='${database_secret_arn}' \
  --log-driver=awslogs --log-opt awslogs-region='${region}' \
  --log-opt awslogs-group='${log_group}' --log-opt awslogs-stream="cloudpulse-$(hostname)" \
  '${app_image}'
