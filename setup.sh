#!/usr/bin/env bash
set -eo pipefail

LOG_DIR="logs/setup"
LOG_FILE="${LOG_DIR}/setup_$(date +%Y%m%d_%H%M%S).log"
HCL_GPG="https://apt.releases.hashicorp.com/gpg"
HCL_APT_REPO="https://apt.releases.hashicorp.com"
HCL_RPM_REPO="https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
KEY_DIR="$HOME/.ssh"
KEY_FILE="${KEY_DIR}/id_ed25519"

mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Proxaform is a free proxmox orchestration tool" 
echo "Full source code available under MIT License on GitHub https://github.com/asbedb/proxaform" 
echo "Contributions are welcome"
echo "=========================================="
echo "        Starting Installation             "
echo "=========================================="
if command -v ansible &> /dev/null && command -v terraform &> /dev/null && command -v yq &> /dev/null; then
    echo "Ansible and Terraform and yq are already installed. Skipping package installation..."
else
    echo "Prerequisites missing. Detecting OS to install core dependencies..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_CODENAME=$VERSION_CODENAME
        else
            OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        fi
    else
        echo "Unsupported OS type: $OSTYPE"
        exit 1
    fi
    echo "Detected OS: $OS"
    case "$OS" in
        ubuntu|debian)
            echo "Updating package lists..."
            sudo apt-get update -y
            echo "Installing prerequisites..."
            sudo apt-get install -y software-properties-common curl git python3 python3-pip python3-venv gnupg lsb-release wget
            if [ "$OS" = "ubuntu" ] && ! command -v ansible &> /dev/null; then
                echo "Adding Ansible PPA..."
                sudo add-apt-repository --yes --update ppa:ansible/ansible
            fi
            if ! command -v ansible &> /dev/null; then
                echo "Installing Ansible..."
                sudo apt-get install -y ansible
            fi
            if ! command -v terraform &> /dev/null; then
                echo "Adding HashiCorp GPG key..."
                wget -O- "$HCL_GPG" | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                echo "Adding HashiCorp repository..."
                CODENAME=${OS_CODENAME:-$(lsb_release -cs)}
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] ${HCL_APT_REPO} ${CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
                echo "Updating repositories for Terraform..."
                sudo apt-get update -y
                echo "Installing Terraform..."
                sudo apt-get install -y terraform
            fi
            if ! command -v yq &> /dev/null; then
                echo "Installing yq..."
                sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
                sudo chmod +x /usr/bin/yq
            fi
            ;;
            
        centos|rhel|rocky|almalinux)
            echo "Installing EPEL repository..."
            sudo dnf install -y epel-release
            
            echo "Installing prerequisites..."
            sudo dnf install -y curl git python3 python3-pip dnf-plugins-core
            
            if ! command -v ansible &> /dev/null; then
                echo "Installing Ansible..."
                sudo dnf install -y ansible-core
            fi
            
            if ! command -v terraform &> /dev/null; then
                echo "Adding HashiCorp repository for RHEL-family..."
                sudo dnf config-manager --add-repo "$HCL_RPM_REPO"
                
                echo "Installing Terraform..."
                sudo dnf install -y terraform
            fi
            if ! command -v yq &> /dev/null; then
                echo "Installing yq..."
                sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
                sudo chmod +x /usr/bin/yq
            fi
            ;;
            
        *)
            echo "OS '$OS' is recognized but script installation logic isn't defined for it."
            exit 1
            ;;
    esac
fi
echo ""
echo "=========================================="
echo "Verification..."
echo "=========================================="
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo "Success! $ANSIBLE_VERSION is installed."
else
    echo "Ansible command was not found in PATH."
    exit 1
fi

if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform --version | head -n 1)
    echo "Success! $TF_VERSION is installed."
else
    echo "Terraform command was not found in PATH."
    exit 1
fi

if command -v yq &> /dev/null; then
    YQ_VERSION=$(yq --version | head -n 1)
    echo "Success! $YQ_VERSION is installed."
else
    echo "yq command was not found in PATH."
    exit 1
fi

echo ""
echo "Setting up local SSH key pair..."
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
if [ ! -f "$KEY_FILE" ]; then
    echo "No existing SSH key found. Generating a new ED25519 key pair..."
    ssh-keygen -t ed25519 -C "ansaplays-orchestrator@$(hostname)" -N "" -f "$KEY_FILE"
else
    echo "Found existing SSH key at $KEY_FILE"
fi
PUBLIC_KEY_CONTENT=$(cat "${KEY_FILE}.pub")
mkdir -p secrets
echo "$PUBLIC_KEY_CONTENT" > secrets/id_ed25519.pub
echo "Public key safely mirrored to 'secrets/id_ed25519.pub'."
echo ""
echo "Generating local ansible.cfg..."
if [ ! -f "ansible.cfg" ]; then
    cat <<'EOF' > ansible.cfg
[defaults]
roles_path = ./roles
host_key_checking = False
retry_files_enabled = False
stdout_callback = default
result_format = yaml
EOF
    echo "ansible.cfg created successfully at project root."
else
    echo "Existing ansible.cfg found. Skipping generation..."
fi
echo "=========================================="
echo "Environment ready!"