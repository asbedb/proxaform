# Rundeck Docker Runner

Provisions a two-node homelab stack: a Docker execution host and a Rundeck control plane, wired together so Rundeck can manage, schedule, and dispatch jobs to the Docker host over SSH.

---

## Architecture

| Node     | Inventory Group | Role & Services                                                         |
| -------- | --------------- | ----------------------------------------------------------------------- |
| **VM 1** | `docker_node`   | Runs Docker & Portainer; executes jobs dispatched from Rundeck          |
| **VM 2** | `rundeck_node`  | Runs Rundeck server & `rd` CLI; schedules, manages, and dispatches jobs |

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

Installs Docker Engine, creates the `rundeck-runner` execution user, and deploys Portainer.

```bash
# Option A: Provision VM + Configure
./deploy.sh playbooks/rundeck_docker_runner/01_setup_docker_host.yml

# Option B: Playbook only (existing VM)
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/rundeck_docker_runner/01_setup_docker_host.yml

```

### Step 2: Provision & Configure Rundeck Control Plane (VM 2)

Installs Rundeck and the `rd` CLI tool, generates the dedicated SSH keypair, and configures Rundeck server URL/hostname bindings.

```bash
# Option A: Provision VM + Configure
./deploy.sh playbooks/rundeck_docker_runner/02_setup_rundeck_server.yml

# Option B: Playbook only (existing VM)
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/rundeck_docker_runner/02_setup_rundeck_server.yml

```

> **Recommended VM Specs:** 2 CPU cores, 2 GB RAM.

### Step 3: Authorize SSH Keys, Register Node & Verify Stack

Establishes passwordless SSH trust, creates the initial Rundeck project, registers the Docker host as a managed node resource, and verifies inventory visibility.

```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/rundeck_docker_runner/03_connect_services_verify.yml

```

---

## Service Access & Endpoints

| Service       | Protocol / URL                     | Default Credentials | Notes                                                       |
| ------------- | ---------------------------------- | ------------------- | ----------------------------------------------------------- |
| **Rundeck**   | `http://<rundeck_server_ip>:4440/` | `admin` / `admin`   | Use **HTTP**. Can take ~50s to become available after setup |
| **Portainer** | `https://<docker_server_ip>:9443`  | `admin` / `admin`   | Self-signed SSL certificate                                 |

---

> **Security Warning**
> This setup hardcodes default `admin` / `admin` credentials and unencrypted HTTP communication for convenience in an isolated homelab setting. **Do not expose this stack directly to the internet.** Use Ansible Vault for secrets and configure a reverse proxy with TLS termination for production use.
