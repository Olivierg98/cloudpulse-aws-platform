mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

run "secure_health_platform" {
  command = plan

  assert {
    condition     = module.platform.public_access_blocked
    error_message = "All S3 public access protections must be enabled."
  }

  assert {
    condition     = module.platform.health_route == "GET /health"
    error_message = "The health endpoint must expose GET /health."
  }
}
