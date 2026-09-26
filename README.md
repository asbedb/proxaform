# Proxaform

Proxaform is a free, open-source orchestration tool for provisioning and tearing down Proxmox LXC containers, using a combination of **Bash**, **Terraform**, and **Ansible**. It wraps the full lifecycle — dependency setup, infrastructure provisioning, and post-deploy configuration — into three simple scripts.

## Features

- One-command environment bootstrap (installs Terraform, Ansible and `yq` if missing)
- Interactive prompts to define new container configurations, saved as reusable `.tfvars` files
- Automatic SSH key injection — no keys to copy or paste
- Automatic Ansible inventory generation with group assignment
- Waits for SSH availability before running your playbook
- Playbook selection menu — any `.yml`/`.yaml` file under `playbooks/` is available immediately
- Guarded, confirmation-gated teardown that also cleans up the inventory
- Full run logging to timestamped files under `logs/`

## Documentation

New to Proxaform? Follow the step-by-step guide:

1. **[Getting Started](docs/01_Getting_Started.md)** — prerequisites, Proxmox user & permissions, running `setup.sh`, and how the SSH key works
2. **[First Deployment](docs/02_First_Deployment.md)** — what `.tfvars` files are, how to create them, and a full walkthrough of deploying a container
3. **[Teardown](docs/03_Teardown.md)** — safely removing a deployed container

## Quick Start

For those already comfortable with Proxmox, Terraform and Ansible.

**Requirements:** Ubuntu/Debian or RHEL-family control machine with `sudo` and `nc`; a Proxmox VE user with the [required privileges](docs/01_Getting_Started.md#2b-create-a-role-with-the-required-privileges); an Ubuntu LXC template on your Proxmox storage.

```bash
git clone https://github.com/asbedb/proxaform.git && cd proxaform
./setup.sh                                  # install deps, create SSH key -> secrets/id_ed25519.pub
./deploy.sh playbooks/networking/ping.yml   # provision a container + run a playbook
./destroy.sh                                # tear it down
```

Key points:

- **`.tfvars` files** live in `secrets/`. Create one via the `deploy.sh` wizard, or copy `terraform/terraform.tfvars.example` there and edit it. **One `.tfvars` file = one container** — its state is stored alongside it as `<name>.tfstate`.
- **`authorised_ssh_key` is automatic.** `deploy.sh` injects `secrets/id_ed25519.pub`; do not put it in your `.tfvars`.
- **Passwords are prompted, not stored.** Terraform asks for `proxmox_privileged_user_password` and `container_root_password` at deploy/destroy time.
- **Inventory groups matter.** Every node joins `proxmox_nodes`; add the group named in your playbook's `hosts:` line when prompted.

See the [`.tfvars` reference](docs/02_First_Deployment.md#understanding-tfvars-files) for every variable.

## Directory Structure

```
proxaform/
├── setup.sh                # One-time environment bootstrap
├── deploy.sh               # Provision a container + run a playbook against it
├── destroy.sh              # Tear down a previously deployed container
├── docs/                   # Step-by-step guides
├── terraform/              # Terraform configuration + terraform.tfvars.example
├── playbooks/              # Ansible playbooks, grouped by category
├── roles/                  # Ansible roles used by the playbooks
├── inventory/              # Generated Ansible inventory (hosts.yml)
├── secrets/                # SSH public key, .tfvars and .tfstate files (gitignored)
└── logs/                   # Timestamped run logs (gitignored)
```

## Security Notes

- `secrets/` and `logs/` are excluded from version control via `.gitignore`, along with `*.tfvars`, `*.tfstate*`, `hosts.yml` and other sensitive Terraform artifacts.
- Passwords are not written into `.tfvars` files created by the wizard; Terraform prompts for them each time `deploy.sh` or `destroy.sh` runs. If you add them to a hand-written `.tfvars` file, they are stored in plain text.
- Terraform variables carrying credentials are marked `sensitive = true`, which redacts them from `plan`/`apply` console output.
- Terraform state stores applied values (including passwords) in plaintext. The state files in `secrets/` should be treated as secrets — if you sync, back up, or share them, consider encryption or a remote encrypted backend.
- `insecure = true` is set on the Proxmox provider for convenience with self-signed certificates — replace this with proper TLS verification in production environments.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/asbedb/proxaform).

## License

MIT License. See [LICENSE](https://github.com/asbedb/proxaform/blob/main/LICENSE) for details.
