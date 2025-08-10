# VPC Settings
resource "aws_vpc" "kubeadm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = var.vpc_name
    }
  )
}

# Subnet Settings
resource "aws_subnet" "kubeadm_subnet" {
  vpc_id            = aws_vpc.kubeadm_vpc.id
  cidr_block        = var.vpc_cidr
  availability_zone = var.zone

  tags = merge(
    local.common_tags,
    {
      Name = var.subnet_name
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "kubeadm_gw" {
  vpc_id = aws_vpc.kubeadm_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "kubeadm_gw"
    }
  )
}

# Routing table
resource "aws_route_table" "kubeadm_routing" {
  vpc_id = aws_vpc.kubeadm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubeadm_gw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "kubeadm_routing"
    }
  )
}

resource "aws_route_table_association" "kubeadm_route_association" {
  subnet_id      = aws_subnet.kubeadm_subnet.id
  route_table_id = aws_route_table.kubeadm_routing.id
}

# Security Group
resource "aws_security_group" "kubeadm_sg" {
  vpc_id = aws_vpc.kubeadm_vpc.id
  name   = "kubeadm-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.control_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.control_cidr]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "kubeadm_sg"
    }
  )
}