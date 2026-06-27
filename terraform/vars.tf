variable "proxmox_host" {
    default = "prox"
}

variable "lxc_template_name" {
    default = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}
variable "lxc_template_type"{
    default = "ubuntu"
}

variable "node_host_name"{
    default = "ansible-control-node"
}

variable "node_ipv4_address"{
    default = "192.168.0.150/24"
}

variable "node_default_ipv4_gateway"{
    default = "192.168.0.1"
}

variable "vm_id"{
    default = "200"
}

variable "disk_datastore_id"{
    default = "local-lvm"
}

variable "disk_size"{
    default = 8
}
variable "network_interface_name"{
    default = "eth0"
}

variable "ssh_key" {
    type = string
    sensitive = true
}


variable "nic_name" {
    type = string
    sensitive = true
}

variable "api_url" {
    type = string
    sensitive = true
}

variable virtual_env_user {
    type = string
    sensitive = true
}

variable virtual_env_pass{
    type = string
    sensitive =  true
}

variable "os_pass"{
    type = string
    sensitive = true
}