variable "proxmox_root_node_name" {
  description = "The name of your root proxmox node"
  type        = string
}

variable "proxmox_lxc_template_name" {
  description = "The linux container template utilised to boot your image example: local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  type        = string
}
variable "proxmox_lxc_template_type" {
  description = "The type of linux container being used example: ubuntu"
  type        = string
}

variable "container_name" {
  description = "Custom name for your container"
  type        = string
}

variable "container_ipv4_address_cidr" {
  description = "Container IPV4 CIDR address"
  type        = string
}

variable "container_ipv4_gateway" {
  description = "Container IPV4 gateway address"
  type        = string
}

variable "vm_id" {
  description = "VM ID used by proxmox"
  type        = number
}

variable "disk_datastore_id" {
  description = "Disk datastore id used by proxmox example:local-lvm"
  type        = string
}

variable "disk_size" {
  description = "Size of disk in gb"
  type        = number
}
variable "container_network_interface_name" {
  description = "A network interface name for the container example: eth0"
  type        = string
}

variable "authorised_ssh_key" {
  description = "This value is the SSH key of a device that is authorised to access this VM - this should be generated client side"
  type        = string
  sensitive   = true
}


variable "container_network_bridge_name" {
  description = "This value is the name of the NIC which acts as a linux bridge within proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_api_url_with_port" {
  description = "This is the proxmox URL the provider will query"
  type        = string
  sensitive   = true
}

variable "proxmox_privileged_user_username" {
  description = "This is the username of the account with necessary permissions to perform operation example: user@pve"
  type        = string
  sensitive   = true
}

variable "proxmox_privileged_user_password" {
  description = "Required for account with necessary permissions to perform operations"
  type        = string
  sensitive   = true
}

variable "container_root_password" {
  description = "Password for containers root user"
  type        = string
  sensitive   = true
}
variable "container_ram_mb" {
  description = "Dedicated RAM for the LXC container in MB"
  type        = number
  default     = 2048 
}

variable "container_swap_mb" {
  description = "Swap memory for the LXC container in MB"
  type        = number
  default     = 512
}

variable "container_cpu_cores" {
  description = "Number of CPU cores dedicated to the LXC container"
  type        = number
  default     = 2
}