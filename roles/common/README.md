# Common Utilities

This role manages baseline utilities, time synchronization (NTP), custom CA certificates, and system welcome banners standard across Linux operating environments.

## Features

- Updates package manager caches (`apt` / `dnf`).
- Installs foundational CLI tools (`curl`, `wget`, `tar`, `git`, `htop`, `rsync`, etc.).
- Configures system NTP time synchronization via `systemd-timesyncd` or `chrony`.
- Deploys custom CA certificates to system trust stores.
- Deploys a standardized dynamic Message of the Day (MOTD).

## Role Variables

Available variables along with default values (see `defaults/main.yml`):

| Variable                      | Default                                                                  | Description                                                                      |
| ----------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| `common_enable_ntp`           | `true`                                                                   | Enable and configure system NTP services.                                        |
| `common_configure_motd`       | `true`                                                                   | Deploy custom `/etc/motd` banner.                                                |
| `common_packages`             | `[curl, wget, tar, unzip, git, htop, net-tools, ca-certificates, rsync]` | Base packages installed across all OS families.                                  |
| `common_ntp_servers`          | `['0.pool.ntp.org', '1.pool.ntp.org', '2.pool.ntp.org']`                 | Primary upstream NTP servers.                                                    |
| `common_fallback_ntp_servers` | `['cloudflare-dns.com', 'time.google.com']`                              | Fallback NTP servers.                                                            |
| `common_custom_ca_certs`      | `[]`                                                                     | List of custom CA certificate files stored in `files/` to install to host store. |

## Example Playbook

Basic inclusion:

```yaml
- hosts: all
  become: true
  roles:
      - role: common
```

## Testing The Role

To run tests locally against your localhost environment:
Bash

`ANSIBLE_CONFIG=ansible.cfg ansible-playbook -K -i roles/common/tests/inventory roles/common/tests/test.yml`

## License

MIT
