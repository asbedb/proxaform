# Docker Host

Installs Docker Engine (via Docker's official APT repository) on a
Debian/Ubuntu target, and creates a dedicated system user for running
automation jobs dispatched against this host (e.g. from Rundeck).

## Requirements

- Debian or Ubuntu target (`ansible_os_family == 'Debian'` is asserted at
  the start of the role; other OS families will fail immediately rather
  than partially apply).
- The `ansible.posix` collection must be installed on the control node
  (used for `ansible.posix.authorized_key`):

    ```bash
    ansible-galaxy collection install ansible.posix
    ```

- Target host must be reachable via SSH with a user capable of `become`
  (sudo/root).

## Role Variables

All variables below are expected in `defaults/main.yml`.

| Variable                 | Description                                                                                                                                                                         |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docker_packages`        | List of prerequisite OS packages installed before adding Docker's repository (e.g. `ca-certificates`, `curl`, `gnupg`)                                                              |
| `docker_gpg_url`         | URL Docker's official GPG signing key is downloaded from                                                                                                                            |
| `docker_gpg_keyring`     | Path the downloaded GPG key is stored at (referenced by `signed_by` in the APT repo definition), e.g. `/etc/apt/keyrings/docker.gpg`                                                |
| `docker_engine_packages` | List of Docker packages installed (e.g. `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`)                                             |
| `docker_runner_user`     | System user created for running dispatched jobs (e.g. `rundeck-runner`)                                                                                                             |
| `docker_runner_group`    | Group the runner user is added to — must be `docker` for the user to control the Docker socket without `sudo`                                                                       |
| `docker_runner_shell`    | Login shell for the runner user (e.g. `/bin/bash`)                                                                                                                                  |
| `docker_runner_ssh_key`  | Public key authorized for the runner user. **Defaults to empty**, and the deploy task is skipped entirely when empty (`when: docker_runner_ssh_key \| length > 0`). See note below. |

## Dependencies

- `ansible.posix` (Ansible Galaxy collection) — required for
  `authorized_key`.

No other Galaxy roles are required.

## Handlers

This role notifies a `Restart Docker` handler after installing Docker
Engine packages. Define it in `handlers/main.yml`, e.g.:

```yaml
- name: Restart Docker
  ansible.builtin.service:
      name: docker
      state: restarted
```

## Example Playbook

```yaml
- name: Provision & Configure Docker Host
  hosts: docker_node
  become: yes

  vars:
      docker_runner_user: "rundeck-runner"
      docker_runner_group: "docker"
      docker_runner_shell: "/bin/bash"
      # Left empty here deliberately — see Role Variables note above.
      docker_runner_ssh_key: ""

  roles:
      - docker_host
```

## Testing

A basic `tests/test.yml` is included. Two dry-run levels are useful before a
real run:

```bash
# Syntax only — no connection made
ansible-playbook -i inventory/hosts.yml roles/docker_host/tests/test.yml --syntax-check

# Structural dry run — validates file/package/user tasks; command-based
# tasks (if any are added later) are skipped, since `command`/`shell`
# don't support --check
ansible-playbook -i inventory/hosts.yml roles/docker_host/tests/test.yml --check --diff
```

Most tasks in this role (`apt`, `file`, `get_url`, `user`, `service`,
`authorized_key`) do support check mode correctly — but a real run
is still the only way to confirm the Docker repository actually adds and
resolves correctly for your target distro/release.

## License

MIT
