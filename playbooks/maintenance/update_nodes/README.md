# Update Nodes

Refreshes the apt package cache and upgrades installed packages on every node in the inventory.

## What It Does

| Step              | Details                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------- |
| **Update cache**  | Runs the equivalent of `apt-get update`                                                     |
| **Upgrade**       | Runs `apt-get upgrade` (or `apt-get dist-upgrade` when `update_nodes_upgrade_type=dist`)    |
| **Clean up**      | Optional `autoremove` and `autoclean` of packages that are no longer needed                 |
| **Reboot check**  | Reports whether `/var/run/reboot-required` exists on each node                              |
| **Reboot**        | Optional, only when `update_nodes_reboot=true` and the node reports a reboot is required    |

Non-Debian nodes are skipped. Rebooting is off by default so nothing restarts unexpectedly; check the report and reboot when convenient.

---

## Usage

```bash
# All nodes
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/maintenance/update_nodes/01_update_nodes.yml

# Limit to a group or host
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/maintenance/update_nodes/01_update_nodes.yml --limit proxmox_nodes

# Full upgrade and reboot nodes that need it
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/maintenance/update_nodes/01_update_nodes.yml -e update_nodes_upgrade_type=dist -e update_nodes_reboot=true
```

## Variables

| Variable                    | Default  | Description                                                          |
| --------------------------- | -------- | -------------------------------------------------------------------- |
| `update_nodes_upgrade_type` | `"safe"` | `safe` for `apt upgrade`, `dist` for `apt full-upgrade`              |
| `update_nodes_autoremove`   | `true`   | Remove unused packages and clean the package cache after upgrading   |
| `update_nodes_reboot`       | `false`  | Reboot nodes that report a reboot is required after upgrading        |
