# 1. Getting Started

This guide prepares both sides of a Proxaform deployment: your **Proxmox host** and the **control machine** that runs Proxaform. By the end you will have a working environment and be ready for [your first deployment](02_First_Deployment.md).

---

## How Proxaform Works

Proxaform is three Bash scripts wrapped around Terraform and Ansible:

| Script       | What it does                                                                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `setup.sh`   | Installs Terraform, Ansible and `yq`, generates an SSH keypair, and writes `ansible.cfg`. Run once.                                              |
| `deploy.sh`  | Picks a playbook, picks (or creates) a `.tfvars` file, provisions an LXC with Terraform, adds it to the Ansible inventory and runs the playbook. |
| `destroy.sh` | Picks a deployment's state file, destroys the container, and removes it from the inventory.                                                      |

```
            ┌────────────── deploy.sh ──────────────┐
.tfvars ──► │ Terraform ──► LXC container ──► Ansible │ ──► configured node
            └─────────────────────────────────────────┘
```

---

## Step 1 — Prepare the Control Machine

The control machine is where you clone and run Proxaform. It needs network access to the Proxmox API (usually port `8006`) and to the IP addresses you will give your containers (port `22`).

Supported operating systems:

- Ubuntu / Debian
- RHEL / CentOS / Rocky Linux / AlmaLinux

You will also need `sudo` rights (for `setup.sh` to install packages) and `nc` (netcat), which `deploy.sh` uses to wait for SSH. Install it if missing:

```bash
# Ubuntu / Debian
sudo apt-get install -y netcat-openbsd
# RHEL family
sudo dnf install -y nmap-ncat
```

---

## Step 2 — Prepare Proxmox

### 2a. Download an LXC template

In the Proxmox UI go to **your storage (e.g. `local`) → CT Templates → Templates** and download an Ubuntu template. Note its full volume ID — you will need it later. You can list downloaded templates from the Proxmox shell:

```bash
pveam list local
# local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

### 2b. Create a role with the required privileges

| Category          | Privileges                                                                             |
| ----------------- | -------------------------------------------------------------------------------------- |
| **Datastore**     | `Allocate`, `AllocateSpace`, `AllocateTemplate`, `Audit`                               |
| **Mapping**       | `Audit`, `Modify`                                                                      |
| **Permissions**   | `Modify`                                                                               |
| **Pool**          | `Allocate`, `Audit`                                                                    |
| **Realm**         | `AllocateUser`                                                                         |
| **SDN**           | `Allocate`, `Audit`, `Use`                                                             |
| **Sys**           | `AccessNetwork`, `Audit`, `Console`, `Incoming`, `Modify`, `Syslog`                    |
| **User**          | `Modify`                                                                               |
| **VM**            | `Allocate`, `Audit`, `Backup`, `Clone`, `Console`, `Migrate`, `PowerMgmt`, `Replicate` |
| **VM.Config**     | `CDROM`, `CPU`, `Cloudinit`, `Disk`, `HWType`, `Memory`, `Network`, `Options`          |
| **VM.GuestAgent** | `Audit`, `FileRead`, `FileSystemMgmt`, `FileWrite`, `Unrestricted`                     |
| **VM.Snapshot**   | `Snapshot`, `Rollback`                                                                 |

Run on the Proxmox host:

```bash
pveum role add Proxaform -privs "Datastore.Allocate,Datastore.AllocateSpace,Datastore.AllocateTemplate,Datastore.Audit,Mapping.Audit,Mapping.Modify,Permissions.Modify,Pool.Allocate,Pool.Audit,Realm.AllocateUser,SDN.Allocate,SDN.Audit,SDN.Use,Sys.AccessNetwork,Sys.Audit,Sys.Console,Sys.Incoming,Sys.Modify,Sys.Syslog,User.Modify,VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.GuestAgent.Audit,VM.GuestAgent.FileRead,VM.GuestAgent.FileSystemMgmt,VM.GuestAgent.FileWrite,VM.GuestAgent.Unrestricted,VM.Migrate,VM.PowerMgmt,VM.Replicate,VM.Snapshot,VM.Snapshot.Rollback"
```

### 2c. Create a user and grant the role

```bash
pveum user add proxaform@pve --password '<choose-a-strong-password>'
pveum aclmod / -user proxaform@pve -role Proxaform
```

Keep the username (`proxaform@pve`) and password handy. The username goes into your `.tfvars` file; the password is typed in when Terraform asks for it (see [Understanding `.tfvars` files](02_First_Deployment.md#understanding-tfvars-files)).

### 2d. Collect your environment details

Write these down now — the deployment wizard will ask for them:

| Detail                   | Where to find it                                      | Example                                                    |
| ------------------------ | ----------------------------------------------------- | ---------------------------------------------------------- |
| API URL                  | The address you use for the Proxmox web UI            | `https://192.168.1.100:8006/`                              |
| Node name                | Left-hand tree in the Proxmox UI under _Datacenter_   | `pve`                                                      |
| Template volume ID       | Step 2a                                               | `local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst` |
| Disk datastore           | _Datacenter → Storage_ (must allow container content) | `local-lvm`                                                |
| Network bridge           | _Node → System → Network_                             | `vmbr0`                                                    |
| Free static IP + gateway | Your LAN — pick an unused address outside DHCP range  | `192.168.1.50/24`, gateway `192.168.1.1`                   |
| Free VM ID               | Any ID not already used in the Proxmox tree           | `150`                                                      |

---

## Step 3 — Clone and Run Setup

```bash
git clone https://github.com/asbedb/proxaform.git
cd proxaform
chmod +x setup.sh deploy.sh destroy.sh
./setup.sh
```

> All scripts must be run from the repository root — they use relative paths such as `terraform/`, `secrets/` and `playbooks/`.

`setup.sh` will:

1. Install Terraform, Ansible and `yq` if any are missing (skipped entirely if all three are present).
2. Generate an ED25519 SSH keypair at `~/.ssh/id_ed25519` — **skipped if you already have one**, in which case your existing key is used.
3. Copy the **public** key to `secrets/id_ed25519.pub`.
4. Create `ansible.cfg` in the repo root if it doesn't exist.

### About the SSH key

The SSH key is fully automatic — **you never type or paste it anywhere**.

- `secrets/id_ed25519.pub` is read by `deploy.sh` on every run and injected into the new container as root's authorised key.
- Ansible then connects to the container as `root` using the matching private key in `~/.ssh/id_ed25519`.
- If `secrets/id_ed25519.pub` is missing, `deploy.sh` and `destroy.sh` stop and tell you to re-run `./setup.sh`.

If you want to use a different key, replace `secrets/id_ed25519.pub` with that public key and make sure the matching private key is loaded in your SSH agent or is the default key.

---

## Directory Layout After Setup

```
proxaform/
├── setup.sh / deploy.sh / destroy.sh
├── ansible.cfg              # Generated by setup.sh
├── terraform/               # Terraform config + terraform.tfvars.example
├── playbooks/               # Ansible playbooks, grouped by category
├── roles/                   # Ansible roles used by the playbooks
├── inventory/               # hosts.yml is generated here on first deploy
├── secrets/                 # (gitignored) SSH public key, .tfvars and .tfstate files
└── logs/                    # (gitignored) timestamped setup/deploy/destroy logs
```

---

**Next:** [2. First Deployment →](02_First_Deployment.md)
