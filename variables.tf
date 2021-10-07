variable "aws_region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

## AWS Managed AD
variable "mad_admin_username" {
  type    = string
  default = "Administrator"
}

variable "mad_admin_psw_length" {
  type    = number
  default = 15
}

variable "mad_domain_name" {
  type    = string
  default = "mad.sample.com"
}

variable "mad_edition" {
  type    = string
  default = "Standard"
}

variable "mad_type" {
  type    = string
  default = "MicrosoftAD"
}

# ------------------------
# FSx
# ------------------------
variable "fsx_throughput_capacity" {
  type    = number
  default = 16
}

variable "fsx_size" {
  type    = number
  default = 32
}

# ------------------------
# Web Server
# ------------------------
variable "ec2_key_pair_name" {
  type    = string
  default = "sample_key_pair"
}

variable "web_instance_type" {
  type    = string
  default = "t3.medium"
}