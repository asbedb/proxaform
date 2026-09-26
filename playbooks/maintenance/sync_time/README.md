# Sync Time

Syncs the system clock on every node in the inventory and verifies each one is within tolerance of the Ansible controller.

## What It Does

| Step               | Details                                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------------------------ |
| **Detect daemon**  | Uses `chrony` if present (Proxmox VE default), otherwise `systemd-timesyncd`; installs one if neither exists |
| **Set timezone**   | Optional, only when `sync_time_timezone` is set; applied to all nodes including LXC containers               |
| **Force sync**     | Enables NTP, then `chronyc makestep` or a `systemd-timesyncd` restart, and waits for `NTPSynchronized=yes`   |
| **Hardware clock** | Writes system time to the RTC (best effort)                                                                  |
| **Verify**         | Reports each node's time and fails any node drifting more than `sync_time_max_drift` seconds                 |

LXC containers share the host kernel clock, so only their timezone is set; their clock is reported on and verified. Sync the Proxmox host to fix a container's time.

NTP servers are configured by the `common` role (`common_ntp_servers`); this playbook does not change them.

---

## Usage

```bash
# All nodes
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/maintenance/sync_time/01_sync_time.yml

# Limit to a group or host
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/maintenance/sync_time/01_sync_time.yml --limit proxmox_nodes

# Also set the timezone
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory/hosts.yml playbooks/maintenance/sync_time/01_sync_time.yml -e sync_time_timezone=Australia/Sydney
```

## Variables

| Variable                 | Default | Description                                                       |
| ------------------------ | ------- | ----------------------------------------------------------------- |
| `sync_time_timezone`     | `""`    | IANA timezone to apply. Empty leaves the current zone unchanged   |
| `sync_time_max_drift`    | `2`     | Max seconds of drift from the controller before a node fails      |
| `sync_time_wait_retries` | `12`    | Attempts (5s apart) to wait for the daemon to report synchronised |

> **Note:** Drift is measured against the machine running Ansible, so make sure the controller's own clock is correct.
