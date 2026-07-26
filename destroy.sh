#!/usr/bin/env bash
set -eo pipefail

LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/destroy_$(date +%Y%m%d_%H%M%S).log"
TF_DIR="terraform"
SECRETS_DIR="secrets"
PUB_KEY_PATH="${SECRETS_DIR}/id_ed25519.pub"

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

# Find existing tfvars
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
echo "Selected target: ${TF_VARS_FILE}"

echo ""
echo "WARNING: You are about to DESTROY infrastructure defined by:"
echo "         ${TF_VARS_FILE}"
read -rp "Are you sure you want to proceed? Type 'DESTROY' to confirm: " CONFIRMATION

if [ "$CONFIRMATION" != "DESTROY" ]; then
    echo "Aborting teardown. No changes were made."
    exit 0
fi

echo ""
echo ">>> Initiating Terraform Destroy..."

pushd "$TF_DIR" > /dev/null || exit 1

terraform init
terraform destroy -var-file="$TF_VARS_FILE" -var="authorised_ssh_key=${SSH_PUBLIC_KEY}" -auto-approve

popd > /dev/null || exit 1

echo ""
echo "=========================================="
echo "    Teardown Complete Successfully!      "
echo "=========================================="