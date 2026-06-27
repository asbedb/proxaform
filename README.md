# Proxmox Terraform Node Deployment Template

This repository is a template for deploying your first node on your local proxmox cluster using terraform.

It utilizes **Terraform** to provision a lightweight Ubuntu LXC container or any other LXC template of your choice.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

- [Terraform](https://www.terraform.io/downloads) installed on your local machine.
- A running **Proxmox VE** cluster.
- A privileged user account on Proxmox.
- An Ubuntu LXC template downloaded to your Proxmox storage (e.g., `local:vztmpl/ubuntu-24.04...`).

### Privileged User Account Permissions

It is recommended to setup a privleged user account dedicated to terraform to complete the provisioning of your LXC. The Account will require the following permissions to complete the task.

```text
Datastore.Allocate, Datastore.AllocateSpace, Datastore.AllocateTemplate, Datastore.Audit, Mapping.Audit, Mapping.Modify, Permissions.Modify, Pool.Allocate, Pool.Audit, Realm.AllocateUser, SDN.Allocate, SDN.Audit, SDN.Use, Sys.AccessNetwork, Sys.Audit, Sys.Console, Sys.Incoming, Sys.Modify, Sys.Syslog, User.Modify, VM.Allocate, VM.Audit, VM.Backup, VM.Clone, VM.Config.CDROM, VM.Config.CPU, VM.Config.Cloudinit, VM.Config.Disk, VM.Config.HWType, VM.Config.Memory, VM.Config.Network, VM.Config.Options, VM.Console, VM.GuestAgent.Audit, VM.GuestAgent.FileRead, VM.GuestAgent.FileSystemMgmt, VM.GuestAgent.FileWrite, VM.GuestAgent.Unrestricted, VM.Migrate, VM.PowerMgmt, VM.Replicate, VM.Snapshot, VM.Snapshot.Rollback
```

---

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/asbedb/proxaform.git
cd proxaform/terraform

```

### Configure Variables

To securely store your environment details, copy the example variables template into a local `terraform.tfvars` file:

```bash
cp example.terraform.tfvars terraform.tfvars

```

Open your newly created `terraform.tfvars` file and update the parameters with your details:

```hcl
virtual_env_user = "yourusername@pam"
virtual_env_pass = "your-prox-mox-user-password"
api_url          = "https://192.168.0.222:8006/"
nic_name         = "vmbr0"
ssh_key          = "your_ssh_key"
os_pass          = "SecurePasswordForYourAnsibleControlNodeLXC"

```

#### Optional Customizations

In addition to the core variables above, you can review and override the defaults defined in `vars.tf` to match your cluster requirements:

```hcl
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
```

### Deploy with Terraform

Initialize the Proxmox provider, view the execution plan, and apply the configuration to spin up the container:

```bash
terraform init
terraform plan
terraform apply
```
