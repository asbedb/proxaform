# Crontab-UI

Deploys [Crontab-UI](https://github.com/AseaK/crontab-ui) as a systemd service for web-based management of cron jobs. Creates a dedicated service user, provisions an SSH directory with keypair generation for remote execution, installs Crontab-UI globally via NVM/npm, configures database and log paths, and manages service startup and health verification.

## Requirements

- Target host must be running a systemd-based Linux distribution (e.g., Ubuntu, Debian, RHEL).
- Target host must be reachable via SSH with a user capable of `become` (sudo/root).
- The `community.crypto` collection must be installed on the control node:

```bash
ansible-galaxy collection install community.crypto
```

- Target host needs outbound network access to fetch Node.js/NVM packages and install `crontab-ui` via npm.

## Role Variables

All variables below are expected in `defaults/main.yml`.

| Variable              | Description                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------- |
| `crontab_user`        | Dedicated system user account created to own Crontab-UI process files and SSH keys (default: `crontab`). |
| `crontab_group`       | Primary system group created for the Crontab-UI user (default: `crontab`).                               |
| `crontab_ssh_key_dir` | Directory path where the runner SSH keypair is stored (default: `/var/lib/crontab/.ssh`).                |
| `crontab_key_type`    | SSH key algorithm used for keypair generation, e.g., `ed25519` or `rsa` (default: `ed25519`).            |
| `cron_db_path`        | Host filesystem path where Crontab-UI stores its JSON database and execution logs.                       |
| `port`                | Network port on which the Crontab-UI web interface listens (default: `8000`).                            |
| `base_url`            | Optional path prefix for serving Crontab-UI behind a reverse proxy (default: `""`).                      |

**Behavior note on SSH directory permissions:** The role explicitly creates `/var/lib/crontab/.ansible/tmp` and configures `/var/lib/crontab/.ssh` permissions to prevent unprivileged Ansible `become_user` execution warnings when tasks run as the `crontab` user.

## Dependencies

- `community.crypto` (Ansible Galaxy collection) — required for `openssh_keypair`.

Functionally depends on Node.js/npm being present or managed via NVM on the target, but this is handled internally by the role tasks.

## Handlers

This role notifies a `Restart crontab-ui` handler when the systemd unit file is updated. Define it in `handlers/main.yml`, e.g.:

```yaml
- name: Restart crontab-ui
  ansible.builtin.systemd:
      name: crontab-ui
      state: restarted
      daemon_reload: true
```

## Example Playbook

```yaml
- name: Deploy Crontab-UI Control Plane
  hosts: crontab_hosts
  become: yes

  vars:
      crontab_user: "crontab"
      crontab_group: "crontab"
      crontab_ssh_key_dir: "/var/lib/crontab/.ssh"
      crontab_key_type: "ed25519"
      CRON_DB_PATH: "/var/lib/crontab/db"
      PORT: 8000
      BASE_URL: ""

  roles:
      - crontab-ui
```

After deployment, Crontab-UI is reachable at `http://<host>:{{ PORT }}{{ BASE_URL }}`. Public key for target host trust authorization is generated at `{{ crontab_ssh_key_dir }}/id_{{ crontab_key_type }}.pub`.

## Testing

A basic `tests/test.yml` is included.

```bash
# Syntax only — no connection made
ansible-playbook -i inventory/hosts.yml roles/crontab-ui/tests/test.yml --syntax-check

# Structural dry run
ansible-playbook -i inventory/hosts.yml roles/crontab-ui/tests/test.yml --check --diff

```

## License

MIT
