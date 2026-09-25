# Technitium

Deploys [Technitium](https://github.com/TechnitiumSoftware/DnsServer/tree/master) as a systemd service providing a self hosted DNS service for home networks.

## Requirements

- Target host must be running a systemd-based Linux distribution (e.g., Ubuntu, Debian, RHEL).
- Target host must be reachable via SSH with a user capable of `become` (sudo/root).
- Target host needs outbound network access to fetch packages and installation binary.

## Role Variables

All variables below are expected in `defaults/main.yml`.

| Variable                          | Description                                                                            |
| --------------------------------- | -------------------------------------------------------------------------------------- |
| `technitium_version`              | Which version of Technitium to install.                                                |
| `technitium_dotnet_channel`       | ASP.NET Core runtime channel required by Technitium.                                   |
| `technitium_install_msquic`       | Install libmsquic for DNS-over-QUIC / HTTP/3 (package must exist in your apt sources). |
| `technitium_disable_resolved`     | Free port 53.                                                                          |
| `technitium_manage_resolve`       | Point the host at the local DNS server.                                                |
| `technitium_server_service_user`  | Local service user username.                                                           |
| `technitium_server_service_group` | Local service user usergroup.                                                          |

## Handlers

This role notifies a `Reload systemd` handler and a `Restart dns` handler - see code below:

```yml
---
- name: Reload systemd
  ansible.builtin.systemd_service:
      daemon_reload: true
  become: true

- name: Restart dns
  ansible.builtin.systemd_service:
      name: dns.service
      state: restarted
  become: true
```

## Example Playbook

```yaml
---
- name: Deploy Technitium DNS Server
  hosts: technitium_node
  become: yes

  roles:
      - technitium
```

After deployment, Tehcnitium can be reached at `http://<host>:5380`.

## Testing

A basic `tests/test.yml` is included.

```bash
# Syntax only — no connection made
ansible-playbook -i inventory/hosts.yml roles/technitium/tests/test.yml --syntax-check

# Structural dry run
ansible-playbook -i inventory/hosts.yml roles/technitium/tests/test.yml --check --diff

```

## License

MIT
