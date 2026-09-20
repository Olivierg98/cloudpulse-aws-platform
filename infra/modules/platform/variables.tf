variable "project" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must contain lowercase letters, numbers and hyphens only."
  }
}
variable "environment" {
  type = string
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "min_size" {
  type    = number
  default = 2
}
variable "max_size" {
  type    = number
  default = 4
}
variable "desired_capacity" {
  type    = number
  default = 2
}

variable "app_image" {
  description = "Immutable container image URI. Defaults to a public nginx image for an infrastructure-only deployment."
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:stable-alpine"
}

variable "use_private_subnets" {
  description = "Place application instances in private subnets. Requires enable_nat_gateway for bootstrap egress."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create one NAT gateway for the private application subnets. This incurs hourly charges."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, HTTPS is enabled and HTTP redirects to HTTPS."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Attach an AWS managed-rule WAF web ACL to the ALB."
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Optional email endpoint for CloudWatch alarms. AWS requires subscription confirmation."
  type        = string
  default     = null
}

variable "enable_database" {
  description = "Provision an encrypted Multi-AZ-ready RDS PostgreSQL database and Secrets Manager secret."
  type        = bool
  default     = false
}

variable "database_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "database_multi_az" {
  type    = bool
  default = false
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for the account/region."
  type        = bool
  default     = false
}

variable "monthly_budget_gbp" {
  description = "Monthly AWS budget threshold in GBP. Set to null to disable."
  type        = number
  default     = 40
}
