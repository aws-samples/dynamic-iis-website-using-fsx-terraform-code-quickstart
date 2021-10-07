resource "aws_security_group" "r53_mad_endpoint_sec_group" {
  name   = format("%s-r53-mad-endpoint-sec-group", var.resource_prefix)
  vpc_id = module.main.vpc_id
  description = "Route53 resolver endpoint Security Group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow outbound for route53 endpoint to MAD"
  }

  tags = merge(
    {
      "Name" = format("%s-r53-mad-endpoint-sec-group", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_route53_resolver_endpoint" "r53_mad_endpoint" {
  name      = format("%s-r53-mad-endpoint", var.resource_prefix)
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.r53_mad_endpoint_sec_group.id
  ]

  ip_address {
    subnet_id = module.main.web_private_subnet_ids[0]
  }

  ip_address {
    subnet_id = module.main.web_private_subnet_ids[1]
  }

  tags = merge(
    {
      "Name" = format("%s-r53-mad-endpoint", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_route53_resolver_rule" "r53_mad_endpoint_fwd_rule" {
  domain_name          = var.mad_domain_name
  name                 = format("%s-r53-mad-endpoint-fwd-rule", var.resource_prefix)
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.r53_mad_endpoint.id

  target_ip {
    ip = tolist(aws_directory_service_directory.mad.dns_ip_addresses)[0]
  }

  target_ip {
    ip = tolist(aws_directory_service_directory.mad.dns_ip_addresses)[1]
  }

  tags = merge(
    {
      "Name" = format("%s-r53-mad-endpoint-fwd-rule", var.resource_prefix)
    },
    var.tags
  )
}

output "dns_ip_addresses" {
  value=aws_directory_service_directory.mad.dns_ip_addresses
}

resource "aws_route53_resolver_rule_association" "r53_mad_endpoint_fwd_rule" {
  resolver_rule_id = aws_route53_resolver_rule.r53_mad_endpoint_fwd_rule.id
  vpc_id           = module.main.vpc_id
}