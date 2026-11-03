terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "random_string" "suffix" {
  length = 6
  special = false
  upper = false
}

locals {
  prefix = "${var.project}-${var.environment}-${random_string.suffix.result}"
  tags = {
    project = var.project
    environment = var.environment
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name = "rg-${local.prefix}"
  location = var.location
  tags = local.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name = "log-${local.prefix}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "PerGB2018"
  retention_in_days = 30
  tags = local.tags
}

resource "azurerm_container_registry" "main" {
  name = "acr${replace(local.prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  sku = "Basic"
  admin_enabled = false
  tags = local.tags
}

resource "azurerm_container_app_environment" "main" {
  name = "cae-${local.prefix}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags = local.tags
}

resource "azurerm_user_assigned_identity" "app" {
  name = "id-${local.prefix}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id = azurerm_user_assigned_identity.app.principal_id
}

# Bootstrap with a public demo image. The pipeline switches to the CloudPulse
# image in ACR after the first build. Terraform intentionally ignores image
# updates made by the release pipeline.
resource "azurerm_container_app" "main" {
  name = "ca-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode = "Multiple"
  tags = local.tags

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  registry {
    server = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.app.id
  }

  ingress {
    external_enabled = true
    target_port = 8000
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1
    container {
      name = "cloudpulse"
      image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu = 0.25
      memory = "0.5Gi"
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
  depends_on = [azurerm_role_assignment.acr_pull]
}
