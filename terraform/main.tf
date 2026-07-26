terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.110.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url_with_port
  username = var.proxmox_privileged_user_username
  password = var.proxmox_privileged_user_password
  insecure = true
}

resource "proxmox_virtual_environment_container" "ubuntu_container" {
  node_name    = var.proxmox_root_node_name
  vm_id        = var.vm_id
  unprivileged = true
  features {
    nesting = true
  }
  initialization {
    hostname = var.container_name
    user_account {
      password = var.container_root_password
      keys     = [var.authorised_ssh_key]
    }
    ip_config {
      ipv4 {
        address = var.container_ipv4_address_cidr
        gateway = var.container_ipv4_gateway
      }
    }
  }

  network_interface {
    name   = var.container_network_interface_name
    bridge = var.container_network_bridge_name
  }

  operating_system {
    template_file_id = var.proxmox_lxc_template_name
    type             = var.proxmox_lxc_template_type
  }

  disk {
    datastore_id = var.disk_datastore_id
    size         = var.disk_size
  }
}