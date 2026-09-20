terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "cloudpulse"
      Environment = "prod"
      ManagedBy   = "terraform"
      Owner       = "Olivier-Gouna"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}
variable "app_image" {
  description = "Immutable ECR image URI, preferably pinned by digest."
  type        = string
}
variable "certificate_arn" {
  type     = string
  default  = null
  nullable = true
}
variable "alarm_email" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}

module "platform" {
  source      = "../../modules/platform"
  project     = "cloudpulse"
  environment = "prod"

  app_image           = var.app_image
  certificate_arn     = var.certificate_arn
  alarm_email         = var.alarm_email
  use_private_subnets = true
  enable_nat_gateway  = true
  enable_waf          = true
  enable_database     = true
  database_multi_az   = false
  enable_guardduty    = true
  monthly_budget_gbp  = 75
}

output "application_url" {
  value = module.platform.url
}
output "ecr_repository_url" {
  value = module.platform.ecr_repository_url
}
output "dashboard" {
  value = module.platform.dashboard
}
