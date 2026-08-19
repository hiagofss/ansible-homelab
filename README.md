# ansible-project

Ansible configuration for provisioning and operating the `oci` server (n8n stack on Oracle Cloud), plus a couple of personal workspace-maintenance utilities.

## Structure

```
.
├── ansible.cfg              # points at inventory/inventory.yaml, sane defaults
├── playbook.yml             # single entrypoint, roles selected via tags
├── requirements.yaml        # collections (ansible-galaxy collection install -r requirements.yaml)
├── Taskfile.yml             # task runner, auto-loads .env
├── docker-compose.yml       # local tooling: ansible creator-ee + AWX
├── .env / .env.example      # secrets and per-host connection vars (never commit .env)
├── inventory/
│   └── inventory.yaml       # hosts (ansible_host/user pulled from .env via lookup('env', ...))
├── group_vars/
│   └── all.yml               # non-secret vars shared by all hosts
├── roles/
│   ├── update/               # apt update/upgrade + reboot-if-needed
│   ├── security/             # UFW, security packages, timezone
│   ├── docker/                # Docker engine install
│   ├── tailscale/             # Tailscale container (mesh VPN)
│   ├── deploy/                 # n8n stack: docker compose + .env template
│   ├── monitoring/             # Uptime Kuma container
│   ├── backup/                  # restic backup of the n8n/postgres volumes to OCI Object Storage
│   ├── workspace_backup/        # zip backup of the local ~/workspace folder
│   └── workspace_sync/          # rsync push of ~/sync to a backup folder
└── examples/
    └── docker_container_demo.yml  # standalone scratch playbook, not part of playbook.yml
```

Each role follows the standard Ansible layout (`tasks/`, and `defaults/`, `handlers/`, `templates/` where needed). Role-specific values live in `defaults/main.yml`; anything shared across roles lives in `group_vars/all.yml`; secrets are never hardcoded — they come from `.env` via `lookup('env', ...)` in the inventory, or from `group_vars/vault.yml` (create with `ansible-vault create group_vars/vault.yml`, referenced as `{{ vault_xxx }}`).

## Requirements

- [Task](https://taskfile.dev) (`brew install go-task`)
- `ansible-core` (tested with 2.21)
- Collections from `requirements.yaml`: run `task` (the default task) to install them

## Setup

1. Copy `.env.example` to `.env` and fill in the values.
2. Run `task` to install the required collections.
3. `task ping` to verify connectivity.

`.env` is only auto-loaded when you run things through `task` (see `dotenv:` in [Taskfile.yml](Taskfile.yml)). If you invoke `ansible`/`ansible-playbook` directly, export it first:

```bash
set -a && source .env && set +a
ansible-playbook playbook.yml --tags update
```

## Running things

`playbook.yml` is the single entrypoint; every role is gated behind a tag. `update` and `security` run by default (no tags needed) since they're safe to apply repeatedly. Every other role is tagged `never`, so it only runs when its tag is requested explicitly — this keeps `task provision`-style default runs from touching things that aren't fully configured yet (e.g. `deploy` needs `group_vars/vault.yml` and a compose file wired up first).

| Task command             | Tag                 | What it does                                  |
|---------------------------|----------------------|------------------------------------------------|
| `task update`             | `update`             | apt update/upgrade, reboot if the kernel changed |
| `task security`           | `security`           | UFW rules, security packages, timezone         |
| `task docker`             | `docker`              | Install the Docker engine                      |
| `task tailscale`          | `tailscale`           | Run the Tailscale container                    |
| `task deploy`             | `deploy`              | Deploy the n8n stack via docker compose        |
| `task monitoring`         | `monitoring`          | Run the Uptime Kuma container                  |
| `task backup`             | `backup`              | restic backup of the n8n/postgres volumes      |
| `task workspace-backup`   | `workspace_backup`    | zip `~/workspace` into `~/backups`             |
| `task workspace-sync`     | `workspace_sync`      | rsync `~/sync` into `~/backup`                 |
| `task check`              | —                    | `--check --diff` dry-run of the default roles  |
| `task ping`               | —                    | `ansible -m ping all`                          |
| `task inventory-list`     | —                    | `ansible-inventory --list`                     |

You can also combine tags directly, e.g. `ansible-playbook playbook.yml --tags docker,tailscale,monitoring`.

## Known gaps

- `deploy` copies `docker-compose.yml` from a `compose/` directory next to the playbook that doesn't exist yet, and templates several `vault_*` variables that aren't defined in `group_vars/vault.yml` yet — set those up before enabling the `deploy` tag.
- `backup` similarly expects `restic_password`, `aws_access_key_id`/`aws_secret_access_key` from the vault.
- `examples/docker_container_demo.yml` is a scratch playbook used to try out the `community.docker` modules; it isn't wired into `playbook.yml` and can be run standalone with `ansible-playbook examples/docker_container_demo.yml` if useful, or deleted once no longer needed.
