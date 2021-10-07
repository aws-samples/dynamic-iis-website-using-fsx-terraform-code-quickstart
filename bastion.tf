data "aws_ami" "custom_bastion_ami" {
  most_recent = "true"
  owners      = ["801119661308"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-2021.09.15"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "bastion_sec_group" {
  name   = format("%s-bastion-sec-group", var.resource_prefix)
  vpc_id = module.main.vpc_id
  description = "Bastion host Security Group"

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow access to website over HTTP connection from the bastion host"
  }

  egress {
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow RDP access to web server over TCP-3389 from the bastion host"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "Allow RDP access to bastion host over TCP-3389 from the internet"
  }

  tags = merge(
    {
      "Name" = format("%s-bastion-sec-group", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.custom_bastion_ami.id
  instance_type               = "t3.micro"
  subnet_id                   = module.main.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sec_group.id]
  associate_public_ip_address = true
  key_name                    = var.ec2_key_pair_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name = format("%s-bastion", var.resource_prefix)
  }
}


data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}