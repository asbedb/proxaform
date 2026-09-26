# 3. Teardown

This guide explains how to remove a container that was deployed with Proxaform.

---

## Step 1 — Run the destroy script

```bash
./destroy.sh
```

## Step 2 — Select the deployment

You pick a **state file** (`.tfstate`), not a `.tfvars` file. There is one state file per deployed container, named after the `.tfvars` file used to create it:

```
Available .tfstate targets in 'secrets/':
------------------------------------------
  [1] secrets/test-01.tfstate
------------------------------------------
Select the tfstate file to DESTROY [1-1]: 1
```

If no state files exist, the script exits — there is nothing deployed to remove.

## Step 3 — Confirm

```
WARNING: You are about to DESTROY infrastructure defined by:
         /path/to/proxaform/secrets/test-01.tfstate
Are you sure you want to proceed? Type 'DESTROY' to confirm: DESTROY
```

Anything other than `DESTROY` (exact, uppercase) aborts with no changes.

## Step 4 — Enter the passwords

As with deployment, Terraform prompts for `container_root_password` and `proxmox_privileged_user_password`, since they are not stored in the `.tfvars` file. The Proxmox password must be correct; the container root password value does not matter for teardown.

## What happens next

1. **Terraform destroy** — the container is removed from Proxmox using the matching `.tfvars` file (`test-01.tfstate` → `test-01.tfvars`). If that file has been deleted, placeholder values are generated so teardown can still proceed.
2. **Inventory clean-up** — the host is removed from every group in `inventory/hosts.yml`, and any groups left empty are pruned.
3. **State clean-up** — `secrets/test-01.tfstate` and its `.backup` are deleted.

Your `.tfvars` file is **kept**, so you can redeploy the same container later by selecting it in `./deploy.sh`. Delete it from `secrets/` if you no longer need it.

Logs for every teardown are saved under `logs/destroy/`.

---

**Back to:** [README](../README.md)
