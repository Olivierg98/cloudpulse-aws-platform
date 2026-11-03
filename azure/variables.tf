variable "subscription_id" {
  description = "Azure subscription ID"
  type = string
}
variable "location" {
  description = "Azure region"
  type = string
  default = "uksouth"
}
variable "project" {
  type = string
  default = "cloudpulse"
}
variable "environment" {
  type = string
  default = "dev"
}
