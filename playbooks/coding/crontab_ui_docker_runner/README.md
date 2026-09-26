# Crontab-UI Docker Runner

Provisions a two-node homelab stack: a Docker execution host and a Crontab-UI control plane, wired together so Crontab-UI can dispatch automated jobs to the Docker host over SSH.

---

## Architecture

| Node     | Inventory Group | Role & Services                                                   |
| -------- | --------------- | ----------------------------------------------------------------- |
| **VM 1** | `docker_node`   | Runs Docker & Portainer; executes jobs dispatched from Crontab-UI |
| **VM 2** | `crontab_node`  | Runs Crontab-UI server; schedules, manages, and dispatches jobs   |

---

## Deployment Workflows

Every step can be run using one of two methods:

- **Bootstrapper (`./deploy.sh <playbook>`)**
  Provisions the target VM/infrastructure first, then executes the playbook. Use this for fresh environments where the VM does not yet exist.
- **Direct Ansible (`ansible-playbook -i inventory/hosts.yml <playbook>`)**
  Executes only the configuration playbook against pre-existing infrastructure.

> **Prerequisite:** Update `inventory/hosts.yml` with your target IP addresses before running any playbooks.

---

## Deployment Steps

### Step 1: Provision & Configure Docker Host (VM 1)

Installs Docker Engine, creates the `docker-runner` execution user, and deploys Portainer.

```bash
# Option A: Provision VM + Configure
./deploy.sh playbooks/coding/crontab_ui_docker_runner/01_setup_docker_host.yml

# Option B: Playbook only (existing VM)
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/coding/crontab_ui_docker_runner/01_setup_docker_host.yml

```

### Step 2: Provision & Configure Crontab-UI Control Plane (VM 2)

Installs Node.js/npm, deploys Crontab-UI as a `systemd` service, creates the `crontab` service user, and generates the dedicated SSH keypair.

```bash
# Option A: Provision VM + Configure
./deploy.sh playbooks/coding/crontab_ui_docker_runner/02_setup_nodejs_crontab_server.yml

# Option B: Playbook only (existing VM)
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/coding/crontab_ui_docker_runner/02_setup_nodejs_crontab_server.yml

```

> **Recommended VM Specs:** 2 CPU cores, 2 GB RAM.

### Step 3: Authorize SSH Trust & Verify Stack

Establishes passwordless SSH access from `crontabui-server` to `docker-server` and verifies cross-node connectivity.

```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/coding/crontab_ui_docker_runner/03_connect_services_verify.yml

```

---

## Service Access & Endpoints

| Service        | Protocol / URL                     | Default Credentials | Notes                               |
| -------------- | ---------------------------------- | ------------------- | ----------------------------------- |
| **Crontab-UI** | `http://<crontab_server_ip>:9000/` | `admin` / `admin`   | Takes ~10s to spin up on first boot |
| **Portainer**  | `https://<docker_server_ip>:9443`  | `admin` / `admin`   | Self-signed SSL certificate         |

---

> **Security Warning**
> This setup hardcodes default `admin` / `admin` credentials and unencrypted HTTP communication for convenience in an isolated homelab setting. **Do not expose this stack directly to the internet.** Use Ansible Vault for secrets and configure a reverse proxy with TLS termination for production use.
