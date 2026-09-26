# Technitium Installation

Provisions a Technitium node after applying common patches and updates.

## Architecture

| Node     | Inventory Group    | Role & Services              |
| -------- | ------------------ | ---------------------------- |
| **VM 1** | `technitiumn_node` | Runs Technitium DNS Software |

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

### Provision & Configure Technitium Server

Installs common tools, creates a service user and deploys technitium on the node.

```bash
# Option A: Provision VM + Configure
./deploy.sh playbooks/networking/technitium/01_deploy_technitium.yml

# Option B: Playbook only (existing VM)
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/networking/technitium/01_deploy_technitium.yml

```

## Service Access & Endpoints

| Service        | Protocol / URL                        | Default Credentials     | Notes                                                 |
| -------------- | ------------------------------------- | ----------------------- | ----------------------------------------------------- |
| **Technitium** | `http://<technitium_server_ip>:5380/` | `change on inital load` | Use **HTTP** and change password on initial page load |
|                |

---

> **Security Warning**
> This setup by default uses unencrypted HTTP communication for convenience in an isolated homelab setting. **Do not expose this stack directly to the internet.** Use Ansible Vault for secrets and configure a reverse proxy with TLS termination for production use.
