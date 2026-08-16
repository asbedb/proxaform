#!/usr/bin/env bash
set -eo pipefail

LOG_DIR="logs"
INVENTORY_DIR="inventory"
LOG_FILE="${LOG_DIR}/deploy_$(date +%Y%m%d_%H%M%S).log"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.ini"
TF_DIR="terraform"
PLAYBOOK_DIR="playbooks"
SECRETS_DIR="secrets"
DEFAULT_TFVARS="${SECRETS_DIR}/terraform.tfvars"
PUB_KEY_PATH="${SECRETS_DIR}/id_ed25519.pub"

mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Proxaform is a free proxmox orchestration tool" 
echo "Full source code available under MIT License on GitHub https://github.com/asbedb/proxaform" 
echo "Contributions are welcome"
echo "=========================================="
echo "         Deployment Orchestrator          "
echo "=========================================="
echo "Run Date: $(date)"
echo "Log file: ${LOG_FILE}"
echo "------------------------------------------"

if [ ! -f "$PUB_KEY_PATH" ]; then
    echo "ERROR: Local SSH key not found at '$PUB_KEY_PATH'."
    echo "Please run './setup.sh' first to generate system secrets."
    exit 1
fi

SSH_PUBLIC_KEY=$(cat "$PUB_KEY_PATH")

PLAYBOOK_PATH="${1:-}"
if [ -z "$PLAYBOOK_PATH" ]; then
    echo ""
    echo "Available playbooks in '${PLAYBOOK_DIR}/':"
    echo "------------------------------------------"
    if [ ! -d "$PLAYBOOK_DIR" ]; then
        echo "ERROR: Directory '${PLAYBOOK_DIR}/' not found."
        exit 1
    fi
    mapfile -t PLAYBOOKS < <(find "$PLAYBOOK_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \) | sort)
    if [ ${#PLAYBOOKS[@]} -eq 0 ]; then
        echo "No .yml or .yaml files found anywhere in '${PLAYBOOK_DIR}/'."
        exit 1
    fi
    for i in "${!PLAYBOOKS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "${PLAYBOOKS[$i]}"
    done
    echo "------------------------------------------"
    while true; do
        read -rp "Select a playbook number [1-${#PLAYBOOKS[@]}]: " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#PLAYBOOKS[@]}" ]; then
            PLAYBOOK_PATH="${PLAYBOOKS[$((CHOICE-1))]}"
            break
        else
            echo "Invalid selection. Please enter a number between 1 and ${#PLAYBOOKS[@]}."
        fi
    done
fi

if [ ! -f "$PLAYBOOK_PATH" ]; then
    echo "ERROR: Selected playbook file '$PLAYBOOK_PATH' does not exist."
    exit 1
fi
echo "--> Selected playbook: ${PLAYBOOK_PATH}"

CREATE_CUSTOM_TFVAR=false
mkdir -p "$SECRETS_DIR"
mapfile -t TFVARS < <(find "$SECRETS_DIR" -maxdepth 1 -type f -name "*.tfvars" | sort)

if [ "${#TFVARS[@]}" -gt 0 ]; then
    echo "Found existing tfvar files in ${SECRETS_DIR}..."
    while true; do
        read -rp "Do you want to create a new tfvars file? (y/n): " USER_INPUT
        if [[ "${USER_INPUT,,}" =~ ^(y|yes)$ ]]; then
            echo "Creating custom tfvars file..."
            CREATE_CUSTOM_TFVAR=true
            break
        elif [[ "${USER_INPUT,,}" =~ ^(n|no)$ ]]; then
            echo "Skipping..."
            CREATE_CUSTOM_TFVAR=false
            break
        else
            echo "Invalid input. Please enter 'y' or 'n'..."
        fi
    done
else
    CREATE_CUSTOM_TFVAR=true
fi

if [ "$CREATE_CUSTOM_TFVAR" = true ]; then
    echo ""
    echo "Creating custom tfvar interactively..."
    read -rp "Proxmox Root Node Name: " PROXMOX_ROOT_NODE_NAME
    read -rp "Proxmox LXC Template Name (example: local:vztmpl/ubuntu-22.04....): " PROXMOX_LXC_TEMPLATE_NAME
    read -rp "Proxmox LXC Template Type (example: ubuntu): " PROXMOX_LXC_TEMPLATE_TYPE
    read -rp "Set Container Name: " CONTAINER_NAME
    read -rp "Set Container IPV4 Address CIDR: " CONTAINER_IPV4_ADDRESS_CIDR
    read -rp "Set Container IPV4 Gateway: " CONTAINER_IPV4_GATEWAY
    read -rp "Set VM ID: " VM_ID
    read -rp "Disk Data Store ID (example: local-lvm): " DISK_DATASTORE_ID
    read -rp "Set Disk Size: " DISK_SIZE
    read -rp "Set Container Network Interface Name (example: eth0): " CONTAINER_NETWORK_INTERFACE_NAME
    read -rp "Proxmox Priviliged User - Username: " PROXMOX_PRIVILEGED_USER_USERNAME
    read -rp "Proxmox API URL with Port (example: https://192.168.0.5:8006/): " PROXMOX_API_URL_WITH_PORT
    read -rp "Container Network Bridge Name (example:vmbr0): " CONTAINER_NETWORK_BRIDGE_NAME
    read -rp "File Name (e.g. custom.tfvars): " FILE_NAME
    TARGET_FILE="${SECRETS_DIR}/${FILE_NAME}"

    cat <<EOF > "$TARGET_FILE"
# Proxmox Provider Configuration
proxmox_api_url_with_port        = "${PROXMOX_API_URL_WITH_PORT}"
proxmox_privileged_user_username = "${PROXMOX_PRIVILEGED_USER_USERNAME}"

# Node & Container Identification
proxmox_root_node_name          = "${PROXMOX_ROOT_NODE_NAME}"
vm_id                           = ${VM_ID}
container_name                  = "${CONTAINER_NAME}"

# Network Settings
container_ipv4_address_cidr    = "${CONTAINER_IPV4_ADDRESS_CIDR}"
container_ipv4_gateway         = "${CONTAINER_IPV4_GATEWAY}"
container_network_interface_name = "${CONTAINER_NETWORK_INTERFACE_NAME}"
container_network_bridge_name   = "${CONTAINER_NETWORK_BRIDGE_NAME}"

# OS Template Settings
proxmox_lxc_template_name       = "${PROXMOX_LXC_TEMPLATE_NAME}"
proxmox_lxc_template_type       = "${PROXMOX_LXC_TEMPLATE_TYPE}"

# Storage Settings
disk_datastore_id               = "${DISK_DATASTORE_ID}"
disk_size                       = ${DISK_SIZE}
EOF

    echo "Successfully created ${TARGET_FILE}"
    SELECTED_TFVAR="$TARGET_FILE"
else
    echo ""
    echo "Available .tfvars files in '${SECRETS_DIR}/':"
    echo "------------------------------------------"
    for i in "${!TFVARS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "$(basename "${TFVARS[$i]}")"
    done
    echo "------------------------------------------"
    while true; do
        read -rp "Select a tfvars file number [1-${#TFVARS[@]}]: " TF_CHOICE
        if [[ "$TF_CHOICE" =~ ^[0-9]+$ ]] && [ "$TF_CHOICE" -ge 1 ] && [ "$TF_CHOICE" -le "${#TFVARS[@]}" ]; then
            SELECTED_TFVAR="${TFVARS[$((TF_CHOICE-1))]}"
            break
        else
            echo "Invalid selection. Enter a number between 1 and ${#TFVARS[@]}."
        fi
    done
fi

TF_VARS_FILE=$(realpath "$SELECTED_TFVAR")
TF_STATE_FILE="${TF_VARS_FILE%.tfvars}.tfstate"
echo "Using tfvars file: ${TF_VARS_FILE}"
echo "Using state file:  ${TF_STATE_FILE}"

echo ""
echo ">>> Step 1/3: Provisioning Node via Terraform..."

if [ ! -d "$TF_DIR" ]; then
    echo "ERROR: Terraform directory '${TF_DIR}' does not exist!"
    exit 1
fi

pushd "$TF_DIR" > /dev/null || exit 1

terraform init
terraform apply -state="$TF_STATE_FILE" -var-file="$TF_VARS_FILE" -var="authorised_ssh_key=${SSH_PUBLIC_KEY}" -auto-approve

NODE_IP=$(terraform output -state="$TF_STATE_FILE" -raw node_ip)
NODE_HOSTNAME=$(terraform output -state="$TF_STATE_FILE" -raw node_hostname)
VM_ID=$(terraform output -state="$TF_STATE_FILE" -raw vm_id)

popd > /dev/null || exit 1

CLEAN_IP=$(echo "$NODE_IP" | cut -d'/' -f1)

echo ""
echo ">>> Step 2/3: Recording Deployment Details & Updating Ansible Inventory..."

if [ ! -f "$INVENTORY_FILE" ]; then
    cat <<EOF > "$INVENTORY_FILE"
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

EOF
fi

mapfile -t EXISTING_GROUPS < <(grep -oP '^\[\K[^\]]+(?=\])' "$INVENTORY_FILE" | grep -v ':vars$' | sort -u)

SELECTED_GROUPS=("proxmox_nodes") # Always include default group

echo ""
echo "Current inventory groups found in '${INVENTORY_FILE}':"
echo "------------------------------------------"
if [ ${#EXISTING_GROUPS[@]} -eq 0 ]; then
    echo " (No user groups found yet)"
else
    for i in "${!EXISTING_GROUPS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "${EXISTING_GROUPS[$i]}"
    done
fi
echo "------------------------------------------"

while true; do
    echo ""
    read -rp "Assign to an existing group [number], type a new group name, or press [Enter] to stick with default '${SELECTED_GROUPS[*]}': " GROUP_INPUT

    if [ -z "$GROUP_INPUT" ]; then
        break
    elif [[ "$GROUP_INPUT" =~ ^[0-9]+$ ]] && [ "$GROUP_INPUT" -ge 1 ] && [ "$GROUP_INPUT" -le "${#EXISTING_GROUPS[@]}" ]; then
        CHOSEN_GROUP="${EXISTING_GROUPS[$((GROUP_INPUT-1))]}"
        SELECTED_GROUPS+=("$CHOSEN_GROUP")
        echo "--> Added node to existing group: ${CHOSEN_GROUP}"
    else
        # Clean custom group string (strip brackets if user typed them)
        CLEAN_GROUP=$(echo "$GROUP_INPUT" | tr -d '[]' | xargs)
        if [ -n "$CLEAN_GROUP" ]; then
            SELECTED_GROUPS+=("$CLEAN_GROUP")
            echo "--> Created and assigned node to new custom group: [${CLEAN_GROUP}]"
        fi
    fi

    read -rp "Add to another group? (y/N): " ADD_MORE
    if [[ ! "${ADD_MORE,,}" =~ ^(y|yes)$ ]]; then
        break
    fi
done

mapfile -t UNIQUE_GROUPS < <(printf "%s\n" "${SELECTED_GROUPS[@]}" | sort -u)

add_host_to_group() {
    local group="$1"
    local hostname="$2"
    local ip="$3"
    local file="$4"

    local host_line="${hostname} ansible_host=${ip} ansible_user=root"

    if grep -q "^\[${group}\]" "$file"; then
        if ! awk -v g="[${group}]" -v h="$hostname" '
            $0 == g {in_section=1; next}
            /^\[/ {in_section=0}
            in_section && $1 == h {found=1}
            END {exit !found}
        ' "$file"; then
            sed -i "/^\[${group}\]/a ${host_line}" "$file"
        fi
    else
        # Append new section to end of file
        echo -e "\n[${group}]\n${host_line}" >> "$file"
    fi
}

for grp in "${UNIQUE_GROUPS[@]}"; do
    add_host_to_group "$grp" "$NODE_HOSTNAME" "$CLEAN_IP" "$INVENTORY_FILE"
done

echo "Ansible inventory successfully updated in '${INVENTORY_FILE}'."

cat <<EOF

==========================================
    DEPLOYMENT SUMMARY & NODE REQUIREMENTS
==========================================
Timestamp:         $(date)
Target Hostname:   ${NODE_HOSTNAME}
Target IP:         ${CLEAN_IP}
VM ID:             ${VM_ID}
SSH User:          root
Playbook Executed: ${PLAYBOOK_PATH}
Inventory File:    ${INVENTORY_FILE}
==========================================

EOF

echo "Waiting for SSH to become responsive on ${CLEAN_IP}..."
until nc -z -w 2 "$CLEAN_IP" 22; do
    echo "Waiting for SSH connection..."
    sleep 2
done
echo "SSH is active!"

echo ""
echo ">>> Step 3/3: Running Ansible Playbook (${PLAYBOOK_PATH})..."

ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_PATH"

echo ""
echo "=========================================="
echo "   Deployment & Automation Complete!      "
echo "=========================================="