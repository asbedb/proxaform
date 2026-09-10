# Node.js (via NVM)

Deploys [Node.js](https://nodejs.org/) using [Node Version Manager (NVM)](https://github.com/nvm-sh/nvm). Downloads and runs the NVM installer, installs the specified Node.js version, sets the default alias, configures [Corepack](https://nodejs.org/api/corepack.html) for managed package managers (like `pnpm` or `yarn`), and installs any configured global `npm` packages.

## Requirements

- Target host must have `curl` or `wget` installed to download the NVM installer script.
- Target host must have standard build/shell tools available (`bash` executable required).
- Target host needs outbound network access to fetch the NVM installer, Node.js binaries, and NPM/Corepack packages.
- Target host must be reachable via SSH. Can be run as a standard user or with `become` (sudo/root) depending on where NVM should reside (`ansible_facts['user_dir']`).

## Role Variables

All variables below are expected in `defaults/main.yml`.

| Variable          | Description                                                                                                                                                                                     |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nvm_url`         | URL to the official NVM installer shell script (default: `[https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh](https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh)`). |
| `node_version`    | Node.js version string to install and alias as default, e.g. `22` or `lts/*` (default: `22`).                                                                                                   |
| `package_manager` | Primary package manager to activate via Corepack (`npm`, `pnpm`, or `yarn`).                                                                                                                    |
| `global_packages` | List of additional npm packages to install globally under NVM (e.g., `['pm2', 'typescript']`).                                                                                                  |

**Behavior note on NVM sourcing:** NVM installs into `~/.nvm` for the targeted execution user (`ansible_facts['user_dir']`). Because NVM relies on shell functions rather than system-wide `/usr/bin` PATH additions, subsequent Ansible tasks using `node`, `npm`, `pnpm`, or `yarn` must source `nvm.sh` prior to execution.

## Dependencies

None.

## Handlers

This role does not require or trigger any handlers.

## Example Playbook

```yaml
- name: Install Node.js and Corepack
  hosts: node_hosts
  become: yes

  vars:
      nvm_url: "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"
      node_version: "22"
      package_manager: "pnpm"
      global_packages:
          - pm2
          - rimraf

  roles:
      - nodejs
```

After deployment, Node.js and the selected package manager are activated under `~/.nvm/versions/node/<resolved_version>/bin`.

## Testing

A basic `tests/test.yml` is included.

```bash
# Syntax only — no connection made
ansible-playbook -i inventory/hosts.yml roles/nodejs/tests/test.yml --syntax-check

# Structural dry run
ansible-playbook -i inventory/hosts.yml roles/nodejs/tests/test.yml --check --diff

```

## License

MIT
