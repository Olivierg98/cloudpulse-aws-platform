terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "cloudpulse"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "Olivier-Gouna"
    }
  }
}
variable "aws_region" {
  type    = string
  default = "eu-west-2"
}
module "platform" {
  source      = "../../modules/platform"
  project     = "cloudpulse"
  environment = "dev"
}
output "application_url" {
  value = module.platform.url
}
