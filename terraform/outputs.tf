output "node_ip" {
  description = "The IP address of the container"
  value       = var.node_ipv4_address
}

output "node_hostname" {
  description = "The hostname of the container"
  value       = var.node_host_name
}

output "vm_id" {
  description = "The LXC Container ID"
  value       = var.vm_id
}