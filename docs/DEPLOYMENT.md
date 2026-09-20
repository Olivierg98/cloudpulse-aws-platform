# Deployment guide

CloudPulse uses GitHub Actions OIDC, so no long-lived AWS access keys are stored in GitHub.

## One-time setup

1. Deploy `infra/bootstrap` with a globally unique state bucket name.
2. Create an AWS IAM role trusted by this repository's GitHub OIDC subject.
3. Grant the role only the services represented in Terraform and permission to assume no other role.
4. Create GitHub environments named `dev` and `prod`; add a required reviewer to `prod`.
5. Add environment secrets `AWS_ROLE_ARN` and `TF_STATE_BUCKET`.
6. For production, optionally add `ACM_CERTIFICATE_ARN` and `ALARM_EMAIL`.

## Release flow

The manual deployment workflow provisions the ECR repository, builds the application, pushes an image tagged with the commit SHA, resolves its immutable digest, applies Terraform and runs the smoke test. Concurrent deployments to the same environment are prevented.

## Rollback

Find the previous healthy image digest in ECR, run Terraform with that digest as `app_image`, and verify `/health`. The Auto Scaling instance refresh replaces instances gradually while ALB health checks protect availability.

## Teardown

Development can be destroyed directly. Production enables database deletion protection and a final snapshot; explicitly review those safeguards before teardown. Never destroy the state bucket before the environments it records.
