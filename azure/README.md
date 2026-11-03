# CloudPulse Phase 2 — Azure Container Apps

This is an **initial Azure development environment**, not a claim of a production-verified deployment. It reuses the existing CloudPulse FastAPI/Docker application and demonstrates Terraform, Azure Container Registry, Container Apps, Log Analytics, managed identity and Azure DevOps CI/CD.

## Architecture
Azure DevOps Pipeline → Azure Container Registry → Azure Container Apps → Log Analytics.

This is intentionally **not** a one-for-one reproduction of the AWS ALB/EC2/ASG architecture. Container Apps reduces setup complexity and can scale to zero. A future enterprise phase could introduce VNet integration, private endpoints, Key Vault, Application Insights, deployment slots/revision traffic shifting and database services.

## Prerequisites
- Azure subscription with permission to create resources and role assignments
- Azure CLI, Terraform >=1.6, Docker
- Azure DevOps organisation/project and an Azure Resource Manager service connection using workload identity federation
- An Azure subscription spending budget/alerts (alerts do not cap spending)

## Provision infrastructure
```bash
az login
az account set --subscription YOUR-SUBSCRIPTION-ID
cd azure
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output
```

The initial app runs a Microsoft demo container as a bootstrap image. **It is not CloudPulse until the CI/CD pipeline deploys the FastAPI image.**

## Configure Azure DevOps
Create pipeline from `azure/azure-pipelines.yml` and set:
- `AZURE_SERVICE_CONNECTION`: Azure Resource Manager service connection name (workload identity federation recommended)
- `ACR_NAME`: `terraform output -raw container_registry_name`
- `RESOURCE_GROUP`: `terraform output -raw resource_group`
- `CONTAINER_APP_NAME`: `terraform output -raw container_app_name`

The service principal needs appropriate rights to push to ACR and update the Container App (for example AcrPush on the registry and Container Apps Contributor on the app/resource group). The Container App's user-assigned identity gets AcrPull from Terraform. Azure DevOps must have access to this GitHub repository.

The pipeline tests the Python application, builds and pushes a uniquely tagged Docker image, updates the Container App, and checks `/health`. Review the repository's Dockerfile and requirements before first run.

**Important:** the example assumes `pytest -q` succeeds with existing tests and that the existing Dockerfile serves port 8000. Confirm both locally first. Depending on provider/API behavior, the initial Container App bootstrap may require adjustment for public-image + managed-identity registry configuration.

## Security and operations
- No registry admin password is enabled; the app pulls via managed identity.
- The pipeline should use federated credentials rather than stored client secrets.
- Log Analytics has usage charges; ACR Basic incurs a standing charge, even when the app scales to zero.
- Local Terraform state can contain sensitive infrastructure data. Never commit `terraform.tfstate`, `.terraform/`, or `terraform.tfvars`. For collaborative use, migrate state to a secured Azure Storage backend.
- This starter does not yet implement HTTPS custom domains, private networking, database, Key Vault, alerts, or automated rollback.
- The pipeline deploys on changes to main; test via a manual run before enabling automatic production releases.

## Teardown
```bash
cd azure
terraform destroy
```
Check Azure portal afterwards for any remaining resources and costs.

## Portfolio evidence checklist
- Screenshot of Terraform plan and successful apply
- Azure DevOps pipeline success with tests and container image push
- Live `/health` response from Container Apps
- Azure Monitor logs from the deployed app
- Document one failure, diagnosis and recovery
