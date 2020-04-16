data "http" "myipaddr" {
    url = "http://ipv4.icanhazip.com"
}

locals {
   host_access_ip = ["${chomp(data.http.myipaddr.body)}/32"]
}

variable "region" {
  description = "The region to create resources."
  default     = "eu-west-2"
}

variable "namespace" {
  description = <<EOH
this is the differantiates different deployment on the same subscription, every cluster should have a different value
EOH
  default = "andrevault"
}



variable "owner" {
description = "IAM user responsible for lifecycle of cloud resources used for training"
default = "andre"
}

variable "created-by" {
description = "Tag used to identify resources created programmatically by Terraform"
default = "Terraform"
}

variable "sleep-at-night" {
description = "Tag used by reaper to identify resources that can be shutdown at night"
default = false
}

variable "TTL" {
description = "Hours after which resource expires, used by reaper. Do not use any unit. -1 is infinite."
default = "240"
}

variable "vpc_cidr_block" {
description = "The top-level CIDR block for the VPC."
default = "10.0.0.0/16"
}

variable "cidr_blocks" {
description = "The CIDR blocks to create the workstations in."
default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "ca_key_algorithm" {
default = "ECDSA"
}

# variable "host_access_ip" {
#   description = "CIDR blocks allowed to connect via SSH on port 22"
#   default = []
# }

variable "ssh_public_key" {
    description = "The contents of the SSH public key to use for connecting to the cluster."
    default = "~/.ssh/id_rsa.pub"
}

variable "zone_id" {
  description = "The CIDR blocks to create the workstations in."
  default     = ""
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "license_file" {
  default = ""
}



variable "vault_transit_private_ip" {
  description = "The private ip of the first Vault node for Auto Unsealing"
  default = "10.0.1.21"
}


variable "vault_leader_names" {
  description = "Names of the Vault nodes that will join the cluster"
  default = "vault_leader"
}

variable "vault_leader_private_ips" {
  description = "The private ip of the first Vault node leader"
  default = "10.0.1.22"
}


variable "vault_follower_names" {
  description = "Names of the Vault nodes that will join the cluster"
  type = list(string)
  default = [ "vault_2", "vault_3"]
}

variable "vault_follower_private_ips" {
  description = "The private ips of the Vault nodes that will join the cluster"
  # @see https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html
  type = list(string)
  default = [ "10.0.1.23", "10.0.1.24" ]
}


# URL for Vault OSS binary
variable "vault_zip_file" {
  default = "https://releases.hashicorp.com/vault/1.4.0/vault_1.4.0_linux_amd64.zip"
}

# Instance size
variable "instance_type" {
  default = "m5.large"
}


# Instance tags for HashiBot AWS resource reaper
# variable hashibot_reaper_owner {}
variable "hashibot_reaper_ttl" {
  default = 48
}



