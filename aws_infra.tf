provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

data "aws_route53_zone" "fdqn" {
  zone_id = var.zone_id
}



resource "aws_vpc" "vault_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_internet_gateway" "vault_ig" {
  vpc_id = aws_vpc.vault_vpc.id

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_route_table" "vault" {
  vpc_id = aws_vpc.vault_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vault_ig.id
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "vault_subnet" {
  count                   = length(var.cidr_blocks)
  vpc_id                  = aws_vpc.vault_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.cidr_blocks[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_route_table_association" "vault" {
  count          = length(var.cidr_blocks)
  route_table_id = aws_route_table.vault.id
  subnet_id      = element(aws_subnet.vault_subnet.*.id, count.index)
}

resource "aws_security_group" "vault_sg" {
  name_prefix = var.namespace
  vpc_id      = aws_vpc.vault_vpc.id

  # SSH access if host_access_ip has CIDR blocks
  dynamic "ingress" {
    for_each = local.host_access_ip
    content {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = [ "${ingress.value}" ]
    }
  }

  # Vault API traffic
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault cluster traffic
  ingress {
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal Traffic
  # ingress {
  #   from_port = 0
  #   to_port   = 0
  #   protocol  = "-1"
  #   self      = true
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.namespace}-${var.owner}"
  public_key = file(var.ssh_public_key)
}

