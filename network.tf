data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

#########################################################
# VPC
#########################################################

resource "aws_vpc" "eks" {
  cidr_block           = var.vpc_id
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "eks-vpc"
  }
}

#########################################################
# Internet Gateway
#########################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.eks.id
}

#########################################################
# Public Subnet (Bastion)
#########################################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-bastion"
  }
}

#########################################################
# Private Subnets
#########################################################

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.eks.id
  availability_zone = local.azs[count.index]

  cidr_block = var.private_subnet_cidrs[count.index]

  tags = {
    Name                              = "private-${local.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

#########################################################
# Public Route Table
#########################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#########################################################
# Private Route Table
#########################################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks.id
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#########################################################
# Security Group For Interface Endpoints
#########################################################

resource "aws_security_group" "vpce" {
  name        = "vpce-sg"
  description = "Allow HTTPS from VPC"
  vpc_id      = aws_vpc.eks.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################################################
# S3 Gateway Endpoint
#########################################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.eks.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]
}

#########################################################
# Interface Endpoints
#########################################################

locals {
  interface_endpoints = [
    "ecr.api",
    "ecr.dkr",
    "sts",
    "ec2",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "logs",
    "monitoring"
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.eks.id
  service_name        = "com.amazonaws.us-east-2.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true

  tags = {
    Name = each.value
  }
}