variable "proxmox_host" {
  description = "The name of your proxmox host"
  type        = string
}

variable "lxc_template_name" {
  description = "The linux container template utilised to boot your image example: local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  type        = string
}
variable "lxc_template_type" {
  description = "The type of linux container being used example: ubuntu"
  type        = string
}

variable "node_host_name" {
  description = "Node host name in proxmox"
  type        = string
}

variable "node_ipv4_address" {
  description = "Node IPV4 CIDR address"
  type        = string
}

variable "node_default_ipv4_gateway" {
  description = "Node IPV4 gateway address"
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
variable "network_interface_name" {
  description = "The network interface name for the vm example: eth0"
  type        = string
}

variable "ssh_key" {
  description = "This value is the SSH key of a device that is authorised to access this VM - this should be generated client side"
  type        = string
  sensitive   = true
}


variable "nic_name" {
  description = "This value is the name of the NIC which acts as a linux bridge within proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_url" {
  description = "This is the proxmox URL the provider will query"
  type        = string
  sensitive   = true
}

variable "virtual_env_user" {
  description = "This is the username of the account with necessary permissions to perform operation example: user@pve"
  type        = string
  sensitive   = true
}

variable "virtual_env_pass" {
  description = "Required for account with necessary permissions to perform operations"
  type        = string
  sensitive   = true
}

variable "os_pass" {
  description = "Credentials for VM root user"
  type        = string
  sensitive   = true
}