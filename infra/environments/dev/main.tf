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
variable "app_image" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:stable-alpine"
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
  environment = "dev"
  app_image   = var.app_image
  alarm_email = var.alarm_email
}
output "application_url" {
  value = module.platform.url
}
output "ecr_repository_url" {
  value = module.platform.ecr_repository_url
}
