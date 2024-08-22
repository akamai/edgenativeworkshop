terraform {
  required_providers {
    linode = {
      source = "linode/linode"
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

variable "userid" {
  description = "User ID or identifier to be used in labels and tags"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "/root/.ssh/id_rsa.pub"
}

variable "regions" {
  description = "List of regions to create Linodes in"
  type        = list(string)
}

locals {
  # Generate current Unix epoch time for timestamp
  timestamp = formatdate("s", timestamp())
}

data "local_file" "ssh_key" {
  filename = var.ssh_public_key
}

locals {
  # Remove newlines from the SSH key content
  sanitized_ssh_key = replace(data.local_file.ssh_key.content, "\n", "")
}

resource "linode_instance" "linode" {
  count       = length(var.regions)
  label       = "${var.userid}-${element(var.regions, count.index)}-${local.timestamp}"
  region      = element(var.regions, count.index)
  type        = "g6-standard-4"
  image       = "linode/ubuntu24.04"
  tags        = toset([var.userid])
  authorized_keys = [local.sanitized_ssh_key]
}

output "linode_labels" {
  value = [for linode in linode_instance.linode : linode.label]
}

output "ip_address" {
  value = [for vm in linode_instance.linode : "${vm.ipv4}"]
}

output "jp_osa_ip_address" {
  value = [for vm in linode_instance.linode : vm.ipv4 if vm.region == "jp-osa"]
  description = "The IP address of the compute instance in the jp-osa region."
}

