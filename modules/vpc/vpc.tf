data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(
    {
      "Name" = format("%s-vpc", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    {
      "Name"  = format("%s-public-subnet-az%s", var.resource_prefix, count.index + 1)
    },
    var.tags
  )
}

resource "aws_subnet" "web_private_subnets" {
  count             = length(var.web_private_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.web_private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    {
      "Name"  = format("%s-web-private-subnet-az%s", var.resource_prefix, count.index + 1)
    },
    var.tags
  )
}

resource "aws_subnet" "data_private_subnets" {
  count             = length(var.data_private_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.data_private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    {
      "Name"  = format("%s-data-private-subnet-az%s", var.resource_prefix, count.index + 1)
      "usage" = "data"
    },
    var.tags
  )
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      "Name"  = format("%s-private-route-table", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block         = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    {
      "Name"  = format("%s-public-route-table", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnets.* [count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_route_table_association_web" {
  count          = length(var.web_private_subnets)
  subnet_id      = aws_subnet.web_private_subnets.* [count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_route_table_association_data" {
  count          = length(var.data_private_subnets)
  subnet_id      = aws_subnet.data_private_subnets.* [count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = format("%s-igw", var.resource_prefix)
  }
}