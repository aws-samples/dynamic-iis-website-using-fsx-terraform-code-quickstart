output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "web_private_subnet_ids" {
  value = aws_subnet.web_private_subnets.*.id
}

output "data_private_subnet_ids" {
  value = aws_subnet.data_private_subnets.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets.*.id
}