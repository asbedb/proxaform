# 2. First Deployment

This guide walks through deploying your first container end-to-end, and explains the `.tfvars` file that describes it. Make sure you've completed [Getting Started](01_Getting_Started.md) first.

---

## Understanding `.tfvars` Files

A `.tfvars` file is a **reusable description of one container**: which Proxmox node it lives on, its ID, name, IP, template, disk and resources. `deploy.sh` hands it to Terraform, which creates a container matching it.

### Where they live

All `.tfvars` files live in `secrets/` (gitignored). Every time you deploy with one, Terraform records what it built in a **state file with the same name** next to it:

```
secrets/
├── id_ed25519.pub          # your SSH public key (from setup.sh)
├── dns-01.tfvars           # what you asked for
└── dns-01.tfstate          # what Terraform actually built
```

### One file = one container

Because the state file is tied to the `.tfvars` name, **each `.tfvars` file manages exactly one container**:

- Re-running `deploy.sh` with the **same** file updates/re-applies that same container — it does not create a second one.
- To create **another** container, create a **new** `.tfvars` file with a different `vm_id`, `container_name` and IP address.

### Three kinds of values

Not everything Terraform needs comes from the `.tfvars` file. Values fall into three groups:

| Kind                       | Variables                                                             | Where the value comes from                                                                            |
| -------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Stored in the file**     | Everything else (node, IDs, network, template, storage, CPU/RAM/swap) | The `.tfvars` file you select or create                                                               |
| **Injected automatically** | `authorised_ssh_key`                                                  | `deploy.sh` reads `secrets/id_ed25519.pub` and passes it to Terraform. **Never enter this yourself.** |
| **Prompted at runtime**    | `proxmox_privileged_user_password`, `container_root_password`         | Terraform asks for them when you deploy (and when you destroy). They are **not** saved in the file.   |

> **About `authorised_ssh_key`:** `terraform/terraform.tfvars.example` lists this variable so the full set of Terraform inputs is visible, but you do **not** need to fill it in. `deploy.sh` always passes your key from `secrets/id_ed25519.pub` on the command line, which takes precedence over any value in the file. Leave it out of your own `.tfvars` files.

### Annotated example

This is what a `.tfvars` file created by the deploy wizard looks like:

```hcl
# Proxmox Provider Configuration
proxmox_api_url_with_port        = "https://192.168.1.100:8006/"  # Proxmox UI address, with port
proxmox_privileged_user_username = "proxaform@pve"                # user from Getting Started, incl. realm

# Node & Container Identification
proxmox_root_node_name          = "pve"         # node name from the Proxmox tree
vm_id                           = 150           # must be unused on the cluster
container_name                  = "dns-01"      # becomes the hostname and the Ansible inventory name

# Network Settings
container_ipv4_address_cidr    = "192.168.1.50/24"  # static IP WITH prefix length
container_ipv4_gateway         = "192.168.1.1"
container_network_interface_name = "eth0"
container_network_bridge_name   = "vmbr0"

# OS Template Settings
proxmox_lxc_template_name       = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
proxmox_lxc_template_type       = "ubuntu"

# Storage Settings
disk_datastore_id               = "local-lvm"
disk_size                       = 8      # GB
container_ram_mb                = 2048   # MB
container_swap_mb               = 512    # MB
container_cpu_cores             = 2

# NOT listed here, on purpose:
#   authorised_ssh_key                -> injected by deploy.sh from secrets/id_ed25519.pub
#   proxmox_privileged_user_password  -> Terraform prompts for it
#   container_root_password           -> Terraform prompts for it
```

### Variable reference

| Variable                           | Description                                          | Example                         |
| ---------------------------------- | ---------------------------------------------------- | ------------------------------- |
| `proxmox_api_url_with_port`        | Proxmox API endpoint                                 | `https://192.168.1.100:8006/`   |
| `proxmox_privileged_user_username` | Proxmox user with the required role, including realm | `proxaform@pve`                 |
| `proxmox_root_node_name`           | Node to create the container on                      | `pve`                           |
| `vm_id`                            | Unique container ID                                  | `150`                           |
| `container_name`                   | Hostname / inventory name                            | `dns-01`                        |
| `container_ipv4_address_cidr`      | Static IPv4 address **with** CIDR suffix             | `192.168.1.50/24`               |
| `container_ipv4_gateway`           | Default gateway                                      | `192.168.1.1`                   |
| `container_network_interface_name` | Interface name inside the container                  | `eth0`                          |
| `container_network_bridge_name`    | Proxmox bridge to attach to                          | `vmbr0`                         |
| `proxmox_lxc_template_name`        | Template volume ID                                   | `local:vztmpl/ubuntu-24.04-...` |
| `proxmox_lxc_template_type`        | OS type of the template                              | `ubuntu`                        |
| `disk_datastore_id`                | Storage for the root disk                            | `local-lvm`                     |
| `disk_size`                        | Root disk size in GB                                 | `8`                             |
| `container_ram_mb`                 | Dedicated RAM in MB (default `2048`)                 | `2048`                          |
| `container_swap_mb`                | Swap in MB (default `512`)                           | `512`                           |
| `container_cpu_cores`              | CPU cores (default `2`)                              | `2`                             |

### Two ways to create a `.tfvars` file

**A. Let the wizard create it (recommended for your first deployment).** `deploy.sh` walks you through each value and saves the file to `secrets/`. This is what the walkthrough below does.

**B. Write it by hand.** Copy the example into `secrets/` and edit it:

```bash
cp terraform/terraform.tfvars.example secrets/dns-01.tfvars
```

Then:

- Delete the `authorised_ssh_key` line — it is supplied automatically.
- Either delete the two password lines (Terraform will prompt for them), **or** keep them to avoid prompts — but be aware they are then stored in plain text on disk.
- The filename **must** end in `.tfvars`, or `deploy.sh` won't list it.

Hand-written files are handy for building several similar containers: copy an existing file, then change `vm_id`, `container_name` and `container_ipv4_address_cidr`.

---

## Walkthrough: Deploy a Test Container

This example deploys a container and runs the `playbooks/networking/ping.yml` playbook, which simply confirms Ansible can reach it. It's the safest way to check everything works before deploying a real service.

### Step 1 — Start the deploy script

```bash
./deploy.sh
```

You can also pass a playbook directly and skip the menu: `./deploy.sh playbooks/networking/ping.yml`.

### Step 2 — Choose a playbook

```
Available playbooks in 'playbooks/':
------------------------------------------
  [1] playbooks/coding/crontab_ui_docker_runner/01_setup_docker_host.yml
  ...
  [7] playbooks/networking/ping.yml
  ...
Select a playbook number [1-8]: 7
```

### Step 3 — Create or pick a `.tfvars` file

- If `secrets/` contains no `.tfvars` files, you go straight into the wizard.
- If some exist, you're asked `Do you want to create a new tfvars file? (y/n)`. Answer `n` to pick an existing file from a numbered list, or `y` to start the wizard.

The wizard asks for each value in turn. Using the details you collected in [Getting Started](01_Getting_Started.md#2d-collect-your-environment-details):

```
Proxmox Root Node Name: pve
Proxmox LXC Template Name (example: local:vztmpl/ubuntu-22.04....): local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst
Proxmox LXC Template Type (example: ubuntu): ubuntu
Set Container Name: test-01
Set Container IPV4 Address CIDR: 192.168.1.50/24
Set Container IPV4 Gateway: 192.168.1.1
Set VM ID: 150
Disk Data Store ID (example: local-lvm): local-lvm
Set Disk Size: 8
Set Container Network Interface Name (example: eth0): eth0
Proxmox Priviliged User - Username: proxaform@pve
Proxmox API URL with Port (example: https://192.168.0.5:8006/): https://192.168.1.100:8006/
Container Network Bridge Name (example:vmbr0): vmbr0
File Name (e.g. custom.tfvars): test-01.tfvars
Dedicated RAM for the LXC container in MB: 2048
Swap memory for the LXC container in MB: 512
Number of CPU cores dedicated to the LXC container: 2
Successfully created secrets/test-01.tfvars
```

Tips:

- Include the `/24` (or your subnet's prefix) on the IP address.
- Name the file after the container (`test-01.tfvars`) so it's easy to find at teardown, and always include the `.tfvars` extension.
- Note that you are **not** asked for the SSH key — it's handled for you.

### Step 4 — Enter the passwords

Terraform now runs and prompts for the two values that are never saved:

```
var.container_root_password
  Password for containers root user
  Enter a value:

var.proxmox_privileged_user_password
  Required for account with necessary permissions to perform operations
  Enter a value:
```

- `container_root_password` — a new root password for the container (console login; Ansible uses the SSH key instead).
- `proxmox_privileged_user_password` — the password of the Proxmox user from Getting Started.

Input is hidden as you type. Terraform then creates the container.

### Step 5 — Assign inventory groups

Once the container exists, it's added to `inventory/hosts.yml`. It always joins the `proxmox_nodes` group, and you're offered extra groups:

```
Assign to an existing group if available by entering the corresponding number,
type a new group name, or press Enter to stick with default 'proxmox_nodes':
```

For `ping.yml`, just press **Enter** — it targets `proxmox_nodes`.

> **Important for real playbooks:** each playbook runs against a specific group (the `hosts:` line at the top of the playbook). The group you enter here must match, or the playbook will find no hosts. For example, `playbooks/networking/technitium/01_deploy_technitium.yml` targets `technitium_node`, so you'd type `technitium_node` at this prompt. Each playbook folder's README lists the groups it expects.

### Step 6 — Wait for SSH and the playbook run

The script prints a deployment summary, waits until port 22 answers on the new IP, then runs the playbook:

```
>>> Step 3/3: Running Ansible Playbook (playbooks/networking/ping.yml)...
TASK [Ping host via Ansible module] ********************************
ok: [test-01]
...
   Deployment & Automation Complete!
```

`ok` on the ping task means Terraform, SSH and Ansible are all working.

### Step 7 — Verify (optional)

```bash
ssh root@192.168.1.50
cat inventory/hosts.yml
```

---

## Next Steps

- Deploy a real service: browse `playbooks/` — each multi-step stack has its own README, e.g. [Technitium](../playbooks/networking/technitium/README.md), [Rundeck Docker Runner](../playbooks/coding/rundeck_docker_runner/README.md), [Crontab-UI Docker Runner](../playbooks/coding/crontab_ui_docker_runner/README.md).
- Re-run a playbook against an existing node without re-provisioning: `ansible-playbook -i inventory/hosts.yml <playbook>`.
- Every run is logged under `logs/deploy/`.

---

## Troubleshooting

| Symptom                                                      | Likely cause / fix                                                                                   |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `ERROR: Local SSH key not found at 'secrets/id_ed25519.pub'` | Run `./setup.sh`.                                                                                    |
| My `.tfvars` file isn't listed                               | It must be inside `secrets/` and end in `.tfvars`.                                                   |
| Terraform errors that the VM ID already exists               | Choose an unused `vm_id`.                                                                            |
| Script sits on `Waiting for SSH connection...`               | Check the IP/gateway/bridge values and that the control machine can reach that subnet.               |
| Playbook reports `skipping: no hosts matched`                | The inventory group you chose doesn't match the playbook's `hosts:` line — see Step 5.               |
| Deploying "again" changed my existing container              | Deploying with the same `.tfvars` targets the same container. Create a new file for a new container. |

---

**Next:** [3. Teardown →](03_Teardown.md)
