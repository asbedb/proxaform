#!/usr/bin/env bash
set -eo pipefail

LOG_DIR="logs/destroy"
LOG_FILE="${LOG_DIR}/destroy_$(date +%Y%m%d_%H%M%S).log"
INVENTORY_DIR="inventory"
TF_DIR="terraform"
SECRETS_DIR="secrets"
PUB_KEY_PATH="${SECRETS_DIR}/id_ed25519.pub"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.yml"


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
mapfile -t TFSTATES < <(find "$SECRETS_DIR" -maxdepth 1 -type f -name "*.tfstate" | sort)

if [ "${#TFSTATES[@]}" -eq 0 ]; then
    echo "ERROR: No .tfstate files found in '${SECRETS_DIR}/'."
    echo "There are no active state targets available to destroy."
    exit 1
fi

echo "Available .tfstate targets in '${SECRETS_DIR}/':"
echo "------------------------------------------"
for i in "${!TFSTATES[@]}"; do
    printf "  [%d] %s\n" "$((i+1))" "$(basename "${TFSTATES[$i]}")"
done
echo "------------------------------------------"

while true; do
    read -rp "Select the tfstate file to DESTROY [1-${#TFSTATES[@]}]: " TF_CHOICE
    if [[ "$TF_CHOICE" =~ ^[0-9]+$ ]] && [ "$TF_CHOICE" -ge 1 ] && [ "$TF_CHOICE" -le "${#TFSTATES[@]}" ]; then
        SELECTED_TFSTATE="${TFSTATES[$((TF_CHOICE-1))]}"
        break
    else
        echo "Invalid selection. Enter a number between 1 and ${#TFSTATES[@]}."
    fi
done

TF_STATE_FILE=$(realpath "$SELECTED_TFSTATE")
MATCHING_TFVARS="${TF_STATE_FILE%.tfstate}.tfvars"
echo "Selected target state: ${TF_STATE_FILE}"

pushd "$TF_DIR" > /dev/null || exit 1
terraform init > /dev/null 2>&1
NODE_IP=$(terraform output -state="$TF_STATE_FILE" -raw node_ip 2>/dev/null || true)
popd > /dev/null || exit 1

CLEAN_IP=$(echo "$NODE_IP" | cut -d'/' -f1)


echo ""
echo "WARNING: You are about to DESTROY infrastructure defined by:"
echo "         ${TF_STATE_FILE}"
read -rp "Are you sure you want to proceed? Type 'DESTROY' to confirm: " CONFIRMATION

if [ "$CONFIRMATION" != "DESTROY" ]; then
    echo "Aborting teardown. No changes were made."
    exit 0
fi

echo ""
echo ">>> Step 1/3: Initiating Terraform Destroy..."

pushd "$TF_DIR" > /dev/null || exit 1

terraform init

if [ -f "$MATCHING_TFVARS" ]; then
    echo "Using matching variable file: ${MATCHING_TFVARS}"
    TARGET_VAR_FILE="$MATCHING_TFVARS"
else
    echo "WARNING: Matching .tfvars file not found at '${MATCHING_TFVARS}'."
    echo "Generating temporary dummy variables to proceed with teardown..."
    TARGET_VAR_FILE=$(mktemp --suffix=.tfvars)
    trap 'rm -f "$TARGET_VAR_FILE"' EXIT
    if [ -f "vars.tf" ]; then
        grep -E '^\s*variable\s+"' vars.tf | cut -d'"' -f2 | while read -r var_name; do
            echo "${var_name} = \"dummy\"" >> "$TARGET_VAR_FILE"
        done
    fi
fi
terraform destroy \
    -var="authorised_ssh_key=${SSH_PUBLIC_KEY}" \
    -state="$TF_STATE_FILE" \
    -var-file="$TARGET_VAR_FILE" \
    -refresh=false \
    -auto-approve \

popd > /dev/null || exit 1
echo ""
echo ">>> Step 2/3: Cleaning Ansible Inventory (${INVENTORY_FILE})..."

if [ -f "$INVENTORY_FILE" ]; then
    if [ -n "$CLEAN_IP" ]; then
        echo "Removing host entries matching IP '${CLEAN_IP}' across all groups using yq..."
        yq eval -i "del(.all.children.[].hosts[] | select(.ansible_host == \"${CLEAN_IP}\"))" "$INVENTORY_FILE"
    elif [ -n "$NODE_HOSTNAME" ]; then
        echo "Removing host entries matching Hostname '${NODE_HOSTNAME}' using yq..."
        yq eval -i "del(.all.children.[].hosts.${NODE_HOSTNAME})" "$INVENTORY_FILE"
    fi
    echo "Pruning empty inventory groups..."
    yq eval -i 'del(.all.children[] | select(.hosts == null or (.hosts | length == 0)))' "$INVENTORY_FILE"
    echo "Ansible YAML inventory successfully cleaned up."
else
    echo "Inventory file '${INVENTORY_FILE}' not found. Skipping inventory update."
fi

echo ""
echo ">>> Step 3/3: Removing State Files..."
if [ -f "$TF_STATE_FILE" ]; then
    rm -f "$TF_STATE_FILE"
    rm -f "${TF_STATE_FILE}.backup"
    echo "Successfully removed state file and backup: ${TF_STATE_FILE}"
else
    echo "State file '${TF_STATE_FILE}' not found. Skipping deletion."
fi

echo ""
echo "=========================================="
echo "    Teardown Complete Successfully!      "
echo "=========================================="