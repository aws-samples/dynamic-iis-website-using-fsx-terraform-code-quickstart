locals {
  DomainJoinCredentialSecretName = format("%s-mad-master-pswrd", var.resource_prefix)  
}

resource "random_password" "mad_master_password" {
  length  = var.mad_admin_psw_length
  special = false
}

resource "aws_secretsmanager_secret" "mad_master_password" {
  name = local.DomainJoinCredentialSecretName
}

resource "aws_secretsmanager_secret_version" "mad_master_password" {
  secret_id     = aws_secretsmanager_secret.mad_master_password.id
  secret_string = <<EOF
{
  "username": "admin",
  "password": "${random_password.mad_master_password.result}",
  "domain": "${var.mad_domain_name}"
}
EOF
}

resource "aws_directory_service_directory" "mad" {
  name     = var.mad_domain_name
  password = random_password.mad_master_password.result
  edition  = var.mad_edition
  type     = var.mad_type

  vpc_settings {
    vpc_id     = module.main.vpc_id
    subnet_ids = module.main.data_private_subnet_ids
  }

  tags = merge(
    {
      "Name" = format("%s-mad", var.resource_prefix)
    },
    var.tags
  )
}