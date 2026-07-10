terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.110.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_url
  username = var.virtual_env_user
  password = var.virtual_env_pass
  insecure = true
}

resource "proxmox_virtual_environment_container" "ubuntu_container" {
  node_name    = var.proxmox_host
  vm_id        = var.vm_id
  unprivileged = true
  features {
    nesting = true
  }
  initialization {
    hostname = var.node_host_name
    user_account {
      password = var.os_pass
    }
    ip_config {
      ipv4 {
        address = var.node_ipv4_address
        gateway = var.node_default_ipv4_gateway
      }
    }
  }

  network_interface {
    name   = var.network_interface_name
    bridge = var.nic_name
  }

  operating_system {
    template_file_id = var.lxc_template_name
    type             = var.lxc_template_type
  }

  disk {
    datastore_id = var.disk_datastore_id
    size         = var.disk_size
  }
}