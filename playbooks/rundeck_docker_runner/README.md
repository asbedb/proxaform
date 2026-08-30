# Rundeck Docker Runner

Provisions a two-node homelab stack: a Docker execution host and a Rundeck control plane, then wire them together so Rundeck can dispatch jobs to the Docker host.

## Architecture

| Node | Inventory group | Role                                                              |
| ---- | --------------- | ----------------------------------------------------------------- |
| VM 1 | `docker_node`   | Runs Docker + Portainer; executes jobs dispatched from Rundeck    |
| VM 2 | `rundeck_node`  | Runs the Rundeck server + `rd` CLI; schedules and dispatches jobs |

## Two ways to run each step

Every step below can be run one of two ways:

- **`./deploy.sh <playbook>`** — the bootstrapper. Provisions the underlying VM/infra first, then runs the given playbook against it. Use this for a clean environment where the VM doesn't exist yet.
- **`ansible-playbook -i inventory/hosts.yml <playbook>`** — runs the playbook only, against a host that's already provisioned and present in inventory. Use this to re-run configuration, pick up changes, or target a VM you built some other way.

Both end up running the exact same playbook — `deploy.sh` just does infra provisioning as an extra step beforehand.

---

## 1. Provision & Configure Docker Host (VM 1)

Installs Docker, creates the `rundeck-runner` execution user, and deploys
Portainer for container management.

```bash
# Bootstrapper: provisions the VM, then configures it
./deploy.sh playbooks/rundeck_docker_runner/01_setup_docker_host.yml

# Playbook only: configures an already-provisioned host
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/rundeck_docker_runner/01_setup_docker_host.yml
```

> **Before running:** add this VM's IP to the `docker_node` group in
> `inventory/hosts.yml`.

---

## 2. Provision & Configure Rundeck Control Plane (VM 2)

Installs Rundeck and the `rd` CLI, generates the SSH keypair Rundeck will use
to reach the Docker host, and configures the Rundeck server's own
URL/hostname bindings.

```bash
# Bootstrapper: provisions the VM, then configures it
./deploy.sh playbooks/rundeck_docker_runner/02_setup_rundeck_server.yml

# Playbook only: configures an already-provisioned host
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/rundeck_docker_runner/02_setup_rundeck_server.yml
```

> **Before running:** add this VM's IP to the `rundeck_node` group in
> `inventory/hosts.yml`.
>
> **Minimum recommended image specs:** 2 GB RAM, 2 CPU cores.

---

## 3. Authorize SSH Keys, Register Node, and Verify Full Stack

Connects the two nodes together inside Rundeck:

- Authorizes the Rundeck server's SSH public key on the Docker host
- Creates the Rundeck project
- Registers the Docker host as a node resource so it can be targeted by jobs
- Confirms the node is visible in Rundeck's inventory

```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/rundeck_docker_runner/03_connect_services_verify.yml
```

This step only runs as a playbook (no `deploy.sh` variant) — it doesn't
provision any infrastructure, it just wires together the two nodes from
steps 1 and 2, which must already exist.

---

## 4. Access the Stack

| Service   | URL                                | Notes                                                                                                                   |
| --------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Rundeck   | `http://<rundeck_server_ip>:4440/` | Use **HTTP**, not HTTPS. Default login: `admin` / `admin`. Can take up to ~50 seconds to become available after step 2. |
| Portainer | `https://<docker_server_ip>:9443`  | Create your admin user on first login.                                                                                  |

**Retrieving the Portainer setup token:** if you miss the first-login window,
access the Docker host's CLI (e.g. via the Proxmox console) and run:

```bash
docker logs portainer 2>&1 | grep -i "token"
```

---

## Security Note

This setup hardcodes the Rundeck default `admin`/`admin` credentials for
convenience, on the assumption this is run in an isolated, non-networked
homelab environment. **If adapting this for anything internet-facing or
production, replace these with Ansible Vault–encrypted credentials (or an
API token) before deploying.**
