data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "main" {
  source = "./modules/vpc"

  resource_prefix      = var.resource_prefix
  vpc_cidr             = "10.0.0.0/16"
  public_subnets       = ["10.0.10.0/24", "10.0.11.0/24"]
  web_private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  data_private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  tags                 = var.tags
}