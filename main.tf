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

variable "ssh_public_key" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "/root/.ssh/id_rsa.pub"
}

variable "regions" {
  description = "List of regions to create Linodes in"
  type        = list(string)
}

# Generate current Unix epoch time for timestamp
locals {
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
  label       = "workshop-${element(var.regions, count.index)}-${local.timestamp}"
  region      = element(var.regions, count.index)
  type        = "g6-standard-1"
  image       = "linode/ubuntu24.04"
  authorized_keys = [local.sanitized_ssh_key]
}

output "linode_labels" {
  value = [for linode in linode_instance.linode : linode.label]
}

output "ip_address" {
  value = [for vm in linode_instance.linode : "${vm.ipv4}"]
}
