# CloudPulse Edge

A serverless extension to the CloudPulse AWS web platform. CloudFront serves a static
page from private S3 using Origin Access Control. A separate API Gateway HTTP API
routes `GET /health` to a Python Lambda. CloudWatch access logs and Lambda logs share
the API request ID. The public health endpoint returns a fixed response and has stage
throttling. CloudFront redirects HTTP to HTTPS.

## Validate locally

Install Terraform 1.11.x and Python 3. From the repository root:

```bash
python3 serverless/package.py
cd serverless
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

The Terraform test uses a mocked AWS provider. It checks the route and S3 public
access settings without deploying resources.

## Deploy with GitLab CI

1. Import or mirror the repository into GitLab and protect its default branch.
2. Use an existing versioned, private S3 Terraform state bucket with encryption.
   Configure the AWS IAM OIDC provider for your GitLab issuer and the
   `sts.amazonaws.com` audience. Create an assumable role with trust restricted to
   the exact GitLab project and protected branch. For GitLab.com, the subject
   follows `project_path:GROUP/PROJECT:ref_type:branch:BRANCH`.
3. Grant the role access to the state object and its `.tflock` file, plus the
   permissions required to manage the resources declared here. Scope
   `iam:PassRole` to the Lambda execution role. The backend role needs
   `s3:ListBucket`, `s3:GetObject` and `s3:PutObject` for state operations as
   applicable, plus `s3:GetObject`, `s3:PutObject` and `s3:DeleteObject` on the lock.
4. Set protected GitLab variables `AWS_ROLE_ARN`, `TF_STATE_BUCKET`,
   `TF_STATE_REGION` and `CLOUDPULSE_DEPLOY=true`. Use a Docker-compatible runner.
5. Run the pipeline on the default branch. Review the plan and start the manual
   deploy job. The plan artifact expires after one day. If it expires or becomes
   stale, run a fresh pipeline and review the new plan.

The pipeline targets one dev account. For another environment, use that account's
credentials and a separate backend bucket or key, and set `TF_VAR_environment=prod`
for a local prod deployment. The shared module is under `modules/platform`.

## Local deployment and cleanup

From `serverless/`, set the shell variables `TF_STATE_BUCKET` and
`TF_STATE_REGION` to your existing backend values and authenticate to AWS.
Verify the account with `aws sts get-caller-identity`, then run:

```bash
python3 package.py
terraform init -reconfigure \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="region=$TF_STATE_REGION" \
  -backend-config="key=cloudpulse-edge/dev.tfstate" \
  -backend-config="use_lockfile=true"
terraform plan -out=local.tfplan
terraform apply local.tfplan
curl -fsSI "$(terraform output -raw site_url)"
curl -fsS -i "$(terraform output -raw health_url)"
```

AWS usage may incur charges. After the demo, confirm the AWS account and backend
key, run `terraform plan -destroy`, then `terraform destroy` from the same
directory when the destroy plan contains only this stack. Leave the pre-existing
state bucket in place. CloudFront changes and teardown can take several minutes.

## Troubleshooting exercises

- **Stale page.** Deploy a small edit to `site/index.html` and inspect
  `curl -I` against the site URL. Record `Age`, `X-Cache` and `Cache-Control`.
  The page advertises a 60-second cache lifetime. Retest after it expires. If
  immediate refresh is required, invalidate both `/` and `/index.html`.
- **Unexpected 403.** Check CloudFront distribution status, the configured origin
  and OAC, then compare the distribution ARN to the bucket policy's
  `AWS:SourceArn`. Direct anonymous S3 access should return 403.
- **Health request.** Record the response's API request ID and match it to
  `requestId` in API Gateway logs and `api_request_id` in Lambda logs.
  Inspect the API integration error field if a request returns 5xx.

Capture actual commands and results after deployment before describing these as
completed drills.
