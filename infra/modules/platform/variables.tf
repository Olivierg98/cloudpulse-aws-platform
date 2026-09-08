variable "project" {
  type = string
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
