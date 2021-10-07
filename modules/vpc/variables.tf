variable "resource_prefix" {
  type        = string
}

variable "tags" {
  type        = map(string)
}

variable "vpc_cidr" {
  type        = string
}

variable "public_subnets" {
  type        = list(string)
}

variable "web_private_subnets" {
  type        = list(string)
}

variable "data_private_subnets" {
  type        = list(string)
}