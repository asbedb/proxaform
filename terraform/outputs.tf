output "node_ip" {
  description = "The IP address of the container"
  value       = var.container_ipv4_address_cidr
}

output "node_hostname" {
  description = "The hostname of the container"
  value       = var.container_name
}

output "vm_id" {
  description = "The LXC Container ID"
  value       = var.vm_id
}