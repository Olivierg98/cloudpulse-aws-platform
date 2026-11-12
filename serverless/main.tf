terraform {
  required_version = "~> 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Use dev or prod."
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "CloudPulse"
      Environment = var.environment
    }
  }
}

data "aws_caller_identity" "current" {}

module "platform" {
  source = "./modules/platform"

  name        = "cloudpulse-edge-${var.environment}"
  bucket_name = "cloudpulse-edge-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.region}"
  bundle_path = "${path.root}/lambda.zip"
  site_path   = "${path.root}/site/index.html"
}

output "site_url" {
  value = "https://${module.platform.domain_name}"
}

output "health_url" {
  value = "${module.platform.api_endpoint}/health"
}
