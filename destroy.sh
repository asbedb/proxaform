#!/usr/bin/env bash
set -eo pipefail

LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/destroy_$(date +%Y%m%d_%H%M%S).log"
TF_DIR="terraform"
SECRETS_DIR="secrets"
PUB_KEY_PATH="${SECRETS_DIR}/id_ed25519.pub"
INVENTORY_FILE="hosts.ini"

mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Proxaform is a free proxmox orchestration tool" 
echo "Full source code available under MIT License on GitHub https://github.com/asbedb/proxaform" 
echo "Contributions are welcome"
echo "=========================================="
echo "           Teardown Orchestrator          "
echo "=========================================="
echo "Run Date: $(date)"
echo "Log file: ${LOG_FILE}"
echo "------------------------------------------"

if [ ! -d "$TF_DIR" ]; then
    echo "ERROR: Terraform directory '${TF_DIR}' does not exist!"
    exit 1
fi

if [ ! -f "$PUB_KEY_PATH" ]; then
    echo "ERROR: Local SSH key not found at '$PUB_KEY_PATH'."
    exit 1
fi
SSH_PUBLIC_KEY=$(cat "$PUB_KEY_PATH")

mkdir -p "$SECRETS_DIR"
mapfile -t TFVARS < <(find "$SECRETS_DIR" -maxdepth 1 -type f -name "*.tfvars" | sort)

if [ "${#TFVARS[@]}" -eq 0 ]; then
    echo "ERROR: No .tfvars files found in '${SECRETS_DIR}/'."
    echo "There are no targeted configurations available to destroy."
    exit 1
fi

echo ""
echo "Available .tfvars targets in '${SECRETS_DIR}/':"
echo "------------------------------------------"
for i in "${!TFVARS[@]}"; do
    printf "  [%d] %s\n" "$((i+1))" "$(basename "${TFVARS[$i]}")"
done
echo "------------------------------------------"

while true; do
    read -rp "Select the tfvars file to DESTROY [1-${#TFVARS[@]}]: " TF_CHOICE
    if [[ "$TF_CHOICE" =~ ^[0-9]+$ ]] && [ "$TF_CHOICE" -ge 1 ] && [ "$TF_CHOICE" -le "${#TFVARS[@]}" ]; then
        SELECTED_TFVAR="${TFVARS[$((TF_CHOICE-1))]}"
        break
    else
        echo "Invalid selection. Enter a number between 1 and ${#TFVARS[@]}."
    fi
done

TF_VARS_FILE=$(realpath "$SELECTED_TFVAR")
TF_STATE_FILE="${TF_VARS_FILE%.tfvars}.tfstate"
echo "Selected target: ${TF_VARS_FILE}"
echo "Target state:  ${TF_STATE_FILE}"

if [ ! -f "$TF_STATE_FILE" ]; then
    echo "WARNING: State file '${TF_STATE_FILE}' does not exist."
    echo "This target may have already been destroyed or was never deployed."
fi


pushd "$TF_DIR" > /dev/null || exit 1
terraform init > /dev/null 2>&1
NODE_IP=$(terraform output -state="$TF_STATE_FILE" -raw node_ip)
popd > /dev/null || exit 1

if [ -z "$NODE_IP" ] && [ -f "$TF_VARS_FILE" ]; then
    NODE_IP=$(grep -oP 'container_ipv4_address_cidr\s*=\s*"\K[^"/]+' "$TF_VARS_FILE" || true)
fi

CLEAN_IP=$(echo "$NODE_IP" | cut -d'/' -f1)

echo ""
echo "WARNING: You are about to DESTROY infrastructure defined by:"
echo "         ${TF_VARS_FILE}"
read -rp "Are you sure you want to proceed? Type 'DESTROY' to confirm: " CONFIRMATION

if [ "$CONFIRMATION" != "DESTROY" ]; then
    echo "Aborting teardown. No changes were made."
    exit 0
fi

echo ""
echo ">>> Step 1/2: Initiating Terraform Destroy..."

pushd "$TF_DIR" > /dev/null || exit 1

terraform init
terraform destroy -state="$TF_STATE_FILE" -var-file="$TF_VARS_FILE" -var="authorised_ssh_key=${SSH_PUBLIC_KEY}" -auto-approve


popd > /dev/null || exit 1
echo ""
echo ">>> Step 2/2: Cleaning Ansible Inventory (${INVENTORY_FILE})..."

if [ -n "$CLEAN_IP" ] && [ -f "$INVENTORY_FILE" ]; then
    echo "Removing entries matching IP: ${CLEAN_IP}..."
    sed -i "/\b${CLEAN_IP}\b/d" "$INVENTORY_FILE"
    TMP_INVENTORY=$(mktemp)
    awk '
    /^\[/ {
        if (header != "" && count == 0 && header !~ /:vars\]$/ && header != "[all:vars]") {
            # Skip empty section header
        } else if (header != "") {
            print header
            for (i = 1; i <= lines_count; i++) {
                print lines[i]
            }
        }
        header = $0
        lines_count = 0
        count = 0
        next
    }
    {
        if (header != "") {
            lines_count++
            lines[lines_count] = $0
            if ($0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]*#/) {
                count++
            }
        } else {
            print $0
        }
    }
    END {
        if (header != "" && count == 0 && header !~ /:vars\]$/ && header != "[all:vars]") {
            # Skip empty trailing section
        } else if (header != "") {
            print header
            for (i = 1; i <= lines_count; i++) {
                print lines[i]
            }
        }
    }
    ' "$INVENTORY_FILE" > "$TMP_INVENTORY"
    cat -s "$TMP_INVENTORY" > "$INVENTORY_FILE"
    rm -f "$TMP_INVENTORY"
    echo "Ansible inventory successfully updated."
else
    echo "No matching IP or inventory file found to clean up. Skipping inventory update."
fi

echo ""
echo "=========================================="
echo "    Teardown Complete Successfully!      "
echo "=========================================="