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
