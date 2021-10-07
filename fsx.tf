locals {
  fsx_creds = jsondecode(aws_secretsmanager_secret_version.mad_master_password.secret_string)
}

resource "aws_security_group" "fsx" {
  name = format("%s-fsx-sg", var.resource_prefix)
  vpc_id = module.main.vpc_id
  description = "FSx Security Group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow outbound from FSx"
  }

  ingress {
    from_port       = 445
    to_port         = 445
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sec_group.id]
    description = "Allow access to FSx over the SMB port TCP-445 from web server"
  }

  tags = merge(
    {
      "Name" = format("%s-fsx-sg", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_fsx_windows_file_system" "fsx" {
  storage_capacity    = var.fsx_size
  subnet_ids          = [module.main.data_private_subnet_ids[0]]
  throughput_capacity = var.fsx_throughput_capacity
  security_group_ids  = [aws_security_group.fsx.id]
  active_directory_id = aws_directory_service_directory.mad.id
  tags = {
    "Name" = format("%s-fsx", var.resource_prefix)
  }
}
