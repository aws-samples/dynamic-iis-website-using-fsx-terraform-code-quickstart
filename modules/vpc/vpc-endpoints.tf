resource "aws_security_group" "vpc_endpoint_sec_group" {
  name        = format("%s-vpc-endpoint-sec-group", var.resource_prefix)
  description = format("Security Group for VPC Endpoint (SSM)")
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.ssm", data.aws_region.current.name)
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sec_group.id]
  subnet_ids          = aws_subnet.data_private_subnets.*.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_msg" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.ssmmessages", data.aws_region.current.name)
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sec_group.id]
  subnet_ids          = aws_subnet.data_private_subnets.*.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.ec2messages", data.aws_region.current.name)
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sec_group.id]
  subnet_ids          = aws_subnet.data_private_subnets.*.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.ec2", data.aws_region.current.name)
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sec_group.id]
  subnet_ids          = aws_subnet.data_private_subnets.*.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.secretsmanager", data.aws_region.current.name)
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sec_group.id]
  subnet_ids          = aws_subnet.data_private_subnets.*.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.logs", data.aws_region.current.name)
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sec_group.id]
  subnet_ids          = aws_subnet.web_private_subnets.*.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = format("com.amazonaws.%s.s3", data.aws_region.current.name)
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private_rt.id
}