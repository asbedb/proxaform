# Rundeck Server

Installs and configures a Rundeck control plane: installs the Java runtime
and Rundeck package, generates the SSH keypair Rundeck will use to reach
execution nodes, binds the server to a specific IP/port, and sets up the
`rd` CLI connection profile for local automation.

This role only configures the Rundeck server itself. It does not create
projects or register execution nodes — that's handled separately, since node registration depends on details of whatever host(s) you
want Rundeck to dispatch jobs to.

## Requirements

- Target host must be reachable via SSH with a user capable of `become`
  (sudo/root).
- The `community.crypto` collection must be installed on the control node
  (used for `community.crypto.openssh_keypair`):

    ```bash
    ansible-galaxy collection install community.crypto
    ```

- Minimum recommended VM specs: 2 GB RAM, 2 CPU cores.

## Role Variables

All variables below live in `defaults/main.yml` and can be overridden per-host
or per-group via `host_vars`/`group_vars`.

| Variable                  | Default                                                                | Description                                                                                                                                      |
| ------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `rundeck_java_package`    | `openjdk-11-jre`                                                       | Java package installed before Rundeck                                                                                                            |
| `rundeck_service_enabled` | `true`                                                                 | Whether the `rundeckd` service is enabled on boot                                                                                                |
| `rundeck_protocol`        | `"http"`                                                               | Protocol used in Rundeck's configured server URL                                                                                                 |
| `rundeck_hostname`        | `"localhost"`                                                          | Hostname portion of `rundeck_grails_url` (not the bind IP — see `rundeck_server_ip` below)                                                       |
| `rundeck_port`            | `4440`                                                                 | Port Rundeck listens on and the `rd` CLI targets                                                                                                 |
| `rundeck_grails_url`      | `"{{ rundeck_protocol }}://{{ rundeck_hostname }}:{{ rundeck_port }}"` | Computed convenience URL                                                                                                                         |
| `rundeck_user`            | `"rundeck"`                                                            | System user Rundeck runs as                                                                                                                      |
| `rundeck_group`           | `"rundeck"`                                                            | System group Rundeck runs as                                                                                                                     |
| `rundeck_home_dir`        | `"/var/lib/rundeck"`                                                   | Home directory of `rundeck_user` — Rundeck's package layout, **not** `/home/<user>`. Used to derive the SSH key and `rd` CLI config paths below. |
| `rundeck_ssh_key_dir`     | `"{{ rundeck_home_dir }}/.ssh"`                                        | Where the Rundeck-to-node SSH keypair is generated                                                                                               |
| `rundeck_key_type`        | `"ed25519"`                                                            | SSH key type generated for node execution                                                                                                        |

Not set in `defaults/main.yml` — expected to be provided by the caller:

| Variable            | Description                                                                                                                                                                                                                                                                                                                                         |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rundeck_server_ip` | The IP Rundeck's `grails.serverURL`/`framework.server.*` properties are bound to. Falls back to `ansible_default_ipv4.address`, then `ansible_host`, if unset. **Set this explicitly** on multi-homed hosts (e.g. WSL, Docker-bridged VMs) where the auto-detected default interface may not be the address you actually want Rundeck reachable on. |

## Dependencies

- `community.crypto` (Ansible Galaxy collection) — required for SSH keypair
  generation.

No other Galaxy roles are required.

## Example Playbook

```yaml
- name: Deploy Rundeck Scheduler Control Plane
  hosts: rundeck_node
  become: yes

  vars:
      rundeck_server_ip: "192.168.0.54" # set explicitly; don't rely on auto-detection
      rundeck_port: 4440

  roles:
      - rundeck_server
```

## Testing

A basic `tests/test.yml` is included. Two dry-run levels are useful before a
real run:

```bash
# Syntax only — no connection made
ansible-playbook -i inventory/hosts.yml roles/rundeck_server/tests/test.yml --syntax-check

# Structural dry run — validates file/config tasks; command-based tasks
# (rd CLI calls) are skipped, since `command`/`shell` don't support --check
ansible-playbook -i inventory/hosts.yml roles/rundeck_server/tests/test.yml --check --diff
```

Note the `--check` limitation above: any `ansible.builtin.command`/`shell`
task is reported as skipped in check mode rather than simulated, since
Ansible can't predict a shell command's output without executing it. A real
(non-check) run against a disposable host is the only way to fully validate
this role.

## License

MIT
