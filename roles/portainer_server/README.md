# Portainer

Deploys [Portainer](https://www.portainer.io/) Community Edition as a
Docker container, for browser-based management of an existing Docker host.
Handles the Python Docker SDK dependency the `community.docker` collection
needs, creates a persistent data volume, and starts the container with the
standard Portainer ports and Docker socket mount.

## Requirements

- **Docker Engine must already be installed and running on the target
  host.** This role does not install Docker itself — it only deploys the
  Portainer container. Pair it with a Docker-installation role of your
  choice.
- The `community.docker` collection must be installed on the control node:

    ```bash
    ansible-galaxy collection install community.docker
    ```

- Target host needs outbound network access to pull the Portainer image
  (default source is Docker Hub).
- Target host must be reachable via SSH with a user capable of `become`
  (sudo/root), and that user needs access to the Docker socket.

## Role Variables

All variables below are expected in `defaults/main.yml`.

| Variable                   | Description                                                                                                                         |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `portainer_volume_name`    | Name of the persistent Docker volume created for Portainer's data (mounted at `/data` in the container)                             |
| `portainer_container_name` | Name given to the running Portainer container                                                                                       |
| `portainer_image`          | Portainer image reference to deploy, e.g. `portainer/portainer-ce:latest` — pin this to a specific tag for reproducible deployments |
| `portainer_restart_policy` | Docker restart policy for the container, e.g. `always` or `unless-stopped`                                                          |
| `portainer_http_port`      | Host port mapped to the container's port `9000` (HTTP UI)                                                                           |
| `portainer_https_port`     | Host port mapped to the container's port `9443` (HTTPS UI)                                                                          |
| `portainer_edge_port`      | Host port mapped to the container's port `8000` (Edge Agent tunnel)                                                                 |
| `portainer_docker_socket`  | Path to the Docker socket on the host, mounted read-write into the container — typically `/var/run/docker.sock`                     |

**Behavior note on the Python Docker SDK install:** the role first tries
`pip install docker`, with `failed_when: false` so a failure (e.g. an
externally-managed-environment restriction on newer Debian/Ubuntu releases)
doesn't stop the play. If that pip install fails, it falls back to the
OS-packaged `python3-docker`. Either path satisfies the dependency
`community.docker` modules need to talk to the Docker Engine API.

## Dependencies

- `community.docker` (Ansible Galaxy collection) — required for
  `docker_volume` and `docker_container`.

Functionally depends on Docker Engine already being present on the target
(see Requirements above), but this isn't declared as a formal Galaxy role
dependency — use whichever Docker-installation role/method fits your setup.

## Handlers

This role notifies a `Restart Portainer` handler after deploying the
container. Define it in `handlers/main.yml`, e.g.:

```yaml
- name: Restart Portainer
  community.docker.docker_container:
      name: "{{ portainer_container_name }}"
      state: started
      restart: yes
```

## Example Playbook

```yaml
- name: Deploy Portainer
  hosts: docker_hosts
  become: yes

  vars:
      portainer_volume_name: "portainer_data"
      portainer_container_name: "portainer"
      portainer_image: "portainer/portainer-ce:2.21.4"
      portainer_restart_policy: "unless-stopped"
      portainer_http_port: 9000
      portainer_https_port: 9443
      portainer_edge_port: 8000
      portainer_docker_socket: "/var/run/docker.sock"

  roles:
      - portainer
```

After deployment, Portainer is reachable at
`https://<host>:{{ portainer_https_port }}` — create your admin user on
first login. If you miss that window, retrieve the setup token from the
host's CLI:

```bash
docker logs <portainer_container_name> 2>&1 | grep -i "token"
```

## Testing

A basic `tests/test.yml` is included.

```bash
# Syntax only — no connection made
ansible-playbook -i inventory/hosts.yml roles/portainer/tests/test.yml --syntax-check

# Structural dry run
ansible-playbook -i inventory/hosts.yml roles/portainer/tests/test.yml --check --diff
```

`docker_volume` and `docker_container` both support check mode, so
`--check --diff` gives reasonably accurate signal here. It won't, however,
catch issues that only surface once the container actually starts (e.g. a
bad image tag, or a port already in use on the host) — a real run is still
worth doing before considering the role verified.

## License

MIT
