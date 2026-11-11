# ADR 001 — Separate AWS environments and control production changes

**Status:** Proposed for production. A pull request plan with mocked AWS data is implemented in CI.

## Context

CloudPulse already has reusable Terraform modules, separate development and production roots, S3 state templates with different keys, and a manually triggered deployment workflow that authenticates to AWS through GitHub OIDC. Development has been deployed. Separate AWS accounts, distinct live roles, and production approval enforcement have yet to be verified.

## Decision

Use one AWS account for development and one for production. Keep each environment's Terraform state in a versioned, encrypted S3 bucket in its own account, with public access blocked and locking enabled. Scope state permissions to that environment's state object and lock. Verify the target account ID before any live plan or apply.

| Stage | Identity and access | Change control |
| --- | --- | --- |
| Pull request | GitHub token with contents read access. No AWS role or remote state access. | Check formatting and validation. Run a speculative development plan with a mocked AWS provider. Require the Terraform check in the repository ruleset before enforcing it as a merge gate. |
| Trusted development branch | Development OIDC role. No access to production state or AWS resources. | Use the existing manual workflow for a live dev plan, apply and smoke test. |
| Production plan | Dedicated production planning role for a trusted workflow on main. Scope it to required resource reads and protected state reads, plus lock operations where needed. | Generate a real plan for a specific commit and immutable image digest. Restrict access to the plan because it can include sensitive values. |
| Production apply | Separate production deploy role. Trust only the repository's protected production environment and the AWS STS audience. Restrict that GitHub environment to main, require an independent reviewer and prevent self-review where supported. | Apply the reviewed saved plan from the same run after approval. Fail if the commit, digest, target account or state has changed. Run smoke checks and retain the deployment evidence. |

Use scoped workload and deploy roles. Limit deploy-role PassRole access to the intended workload roles. Record exceptional access and changes through CloudTrail and GitHub deployment history. Use a dedicated, temporary emergency role with a recorded incident reference, an independent approver and follow-up review.

## Trade-offs

Separate accounts limit the impact of a development role compromise and isolate quotas and billing, at the cost of more account setup, duplicated bootstrap resources and cross-account administration. Distinct production planning and deployment roles reduce write access, while plan data still needs careful handling because state can include sensitive values. A reviewer adds a release dependency. The emergency process gives responders a documented path when routine review is unavailable.

## Demonstration and follow-up

The CI Terraform job validates both environment roots and runs a development plan test using fixture values for AWS data sources. It exercises the shared module without AWS credentials and can run on a pull request. It cannot confirm live IAM permissions, production approval rules or drift. The existing deployment workflow provisions ECR and applies from the selected environment; the proposed reviewed-plan production flow is a follow-up.

Before enabling production, configure the accounts, role trust, state and GitHub protections. Test that a development identity cannot access production state, an unapproved run cannot obtain production write credentials, and an approved run deploys the reviewed plan. Retain the test results with the deployment record.
