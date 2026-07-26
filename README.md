# Proxaform

Proxaform is a free, open-source orchestration tool for provisioning and tearing down Proxmox LXC containers, using a combination of **Bash**, **Terraform**, and **Ansible**. It wraps the full lifecycle — dependency setup, infrastructure provisioning, and post-deploy configuration — into three simple scripts.

## Features

- One-command environment bootstrap (installs Terraform + Ansible if missing)
- Interactive prompts to define new container configurations, saved as reusable `.tfvars` files
- Automatic Ansible inventory generation from Terraform outputs
- Waits for SSH availability before running your playbook
- Playbook selection menu — drop any `.yml`/`.yaml` file into `playbooks/` and it's available immediately
- Guarded, confirmation-gated teardown of previously deployed containers
- Full run logging to timestamped files under `logs/`

## Prerequisites

- A Proxmox VE host with API access
- A privileged Proxmox user/account with permission to create and destroy containers
- One of the following operating systems on the machine running Proxaform:
    - Ubuntu / Debian
    - RHEL / CentOS / Rocky Linux / AlmaLinux
- An Ubuntu LXC template downloaded to your Proxmox storage (e.g., `local:vztmpl/ubuntu-24.04...`).

### Privileged User Account Permissions

It is recommended to setup a privleged user account dedicated to terraform to complete the provisioning of your LXC. The Account will require the following permissions to complete the task.

```text
Datastore.Allocate, Datastore.AllocateSpace, Datastore.AllocateTemplate, Datastore.Audit, Mapping.Audit, Mapping.Modify,
Permissions.Modify, Pool.Allocate, Pool.Audit, Realm.AllocateUser, SDN.Allocate, SDN.Audit, SDN.Use, Sys.AccessNetwork,
Sys.Audit, Sys.Console, Sys.Incoming, Sys.Modify, Sys.Syslog, User.Modify, VM.Allocate, VM.Audit, VM.Backup, VM.Clone,
VM.Config.CDROM, VM.Config.CPU, VM.Config.Cloudinit, VM.Config.Disk, VM.Config.HWType, VM.Config.Memory, VM.Config.Network,
VM.Config.Options, VM.Console, VM.GuestAgent.Audit, VM.GuestAgent.FileRead, VM.GuestAgent.FileSystemMgmt, VM.GuestAgent.FileWrite,
VM.GuestAgent.Unrestricted, VM.Migrate, VM.PowerMgmt, VM.Replicate, VM.Snapshot, VM.Snapshot.Rollback
```

If Terraform and Ansible aren't already installed, `setup.sh` installs them for you.

## Directory Structure

```
proxaform/
├── setup.sh              # One-time environment bootstrap
├── deploy.sh              # Provision a container + run a playbook against it
├── destroy.sh             # Tear down a previously deployed container
├── terraform/             # Terraform configuration (providers, resources, variables)
├── playbooks/              # Your Ansible playbooks (select at deploy time)
├── secrets/                # Generated SSH keys + saved .tfvars configs (gitignored)
├── logs/                   # Timestamped run logs (gitignored)
└── hosts.ini                # Generated Ansible inventory (overwritten each deploy)
```

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/asbedb/proxaform.git
```

### 1. Run the setup script

```bash
./setup.sh
```

This will:

- Detect your OS and install Terraform, Ansible, and required system packages
- Generate a local ED25519 SSH keypair at `~/.ssh/id_ed25519` (skipped if one already exists)
- Mirror the public key to `secrets/id_ed25519.pub` for use during provisioning

### 2. Deploy a container

```bash
./deploy.sh [path/to/playbook.yml]
```

If no playbook path is given, you'll be prompted to choose one from `playbooks/`.

You'll then either:

- Select an existing `.tfvars` config from `secrets/`, or
- Walk through an interactive prompt to define a new one (node name, template, network config, disk size, Proxmox credentials, etc.), which is saved as a new `.tfvars` file for reuse

Once the container is provisioned, Proxaform will:

1. Write the container's connection details to `hosts.ini`
2. Wait for SSH to become reachable
3. Run your selected Ansible playbook against the new container

### 3. Tear down a container

```bash
./destroy.sh
```

Select the `.tfvars` file matching the deployment you want removed, then type `DESTROY` to confirm. This runs `terraform destroy` against that configuration.

## Security Notes

- `secrets/` and `logs/` are excluded from version control via `.gitignore`, along with `*.tfvars`, `*.tfstate*`, and other sensitive Terraform artifacts.
- Proxmox and OS-level credentials are collected at runtime and are not written into saved `.tfvars` files — you'll be prompted for them each time `deploy.sh` or `destroy.sh` needs to authenticate.
- Terraform variables carrying credentials are marked `sensitive = true`, which redacts them from `plan`/`apply` console output.
- Terraform state still stores applied values in plaintext by default. If you sync, back up, or share `terraform.tfstate`, consider enabling state encryption or moving to a remote encrypted backend.
- `insecure = true` is set on the Proxmox provider for convenience with self-signed certificates — replace this with proper TLS verification in production environments.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/asbedb/proxaform). See the repository for contribution guidelines.

## License

MIT License. See [LICENSE](https://github.com/asbedb/proxaform/blob/main/LICENSE) for details.
