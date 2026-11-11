mock_provider "aws" {
  mock_data "aws_availability_zones" {
    override_during = plan
    defaults = {
      names = ["eu-west-2a", "eu-west-2b"]
    }
  }

  mock_data "aws_region" {
    override_during = plan
    defaults = {
      name = "eu-west-2"
    }
  }

  mock_data "aws_ami" {
    override_during = plan
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

run "review_development_plan" {
  command = plan
}
