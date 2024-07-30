terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "Root password for the Linodes"
  type        = string
  sensitive   = true
}

variable "regions" {
  description = "List of regions to create Linodes in"
  type        = list(string)
}

# Generate current Unix epoch time for timestamp
locals {
  timestamp = formatdate("s", timestamp())
}

resource "linode_instance" "linode" {
  count       = length(var.regions)
  label       = "workshop-${element(var.regions, count.index)}-${local.timestamp}"
  region      = element(var.regions, count.index)
  type        = "g6-standard-1"
  image       = "linode/ubuntu24.04"
  root_pass   = var.root_password
}

output "linode_labels" {
  value = [for linode in linode_instance.linode : linode.label]
}

output "ip_address" {
  value = [for vm in linode_instance.linode : "${vm.ipv4}"]
}
