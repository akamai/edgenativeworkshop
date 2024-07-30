output "linode_labels" {
  value = [for linode in linode_instance.linode : linode.label]
}
