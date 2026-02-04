#!/bin/bash
#
# GitHub Actions Self-Hosted Runner Setup Script for Ubuntu/Debian
#
# Usage:
#   1. Get a runner token from GitHub:
#      - Organization: Settings → Actions → Runners → New runner
#      - Download the token
#   2. Run this script: sudo ./scripts/setup-runner.sh <ORGANIZATION_NAME> <RUNNER_TOKEN>
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script with sudo"
    exit 1
fi

# Check arguments
if [ $# -lt 2 ]; then
    log_error "Usage: $0 <ORGANIZATION_NAME> <RUNNER_TOKEN> [RUNNER_NAME]"
    echo ""
    echo "Example:"
    echo "  sudo $0 my-org TOKEN123"
    echo "  sudo $0 my-org TOKEN123 my-runner-01"
    exit 1
fi

ORG_NAME="$1"
RUNNER_TOKEN="$2"
RUNNER_NAME="${3:-$(hostname)}"
RUNNER_DIR="/opt/github-runner"
RUNNER_USER="actions"

log_info "Setting up GitHub Actions runner for organization: $ORG_NAME"
log_info "Runner name: $RUNNER_NAME"

# Update system packages
log_info "Updating system packages..."
apt-get update -y

# Install required packages
log_info "Installing required packages..."
apt-get install -y \
    curl \
    jq \
    docker.io \
    kubectl \
    git

# Create dedicated user for the runner
log_info "Creating runner user: $RUNNER_USER"
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
fi

# Add runner user to docker group
log_info "Adding $RUNNER_USER to docker group..."
usermod -aG docker "$RUNNER_USER"

# Enable and start Docker
log_info "Enabling and starting Docker..."
systemctl enable docker
systemctl start docker

# Create runner directory
log_info "Creating runner directory: $RUNNER_DIR"
mkdir -p "$RUNNER_DIR"
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

# Download latest runner version
log_info "Downloading latest GitHub Actions runner..."
cd "$RUNNER_DIR"

# Get latest runner version
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    ARCH="x64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$ARCH" = "armv7l" ]; then
    ARCH="arm"
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

RUNNER_PACKAGE="actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz"

log_info "Downloading: $RUNNER_PACKAGE"
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PACKAGE}"

# Extract runner package
log_info "Extracting runner package..."
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && tar xzf ./actions-runner.tar.gz"

# Configure the runner
log_info "Configuring runner..."
cd "$RUNNER_DIR"
su - "$RUNNER_USER" -c "cd $RUNNER_DIR && ./config.sh \
    --url https://github.com/${ORG_NAME} \
    --token ${RUNNER_TOKEN} \
    --name ${RUNNER_NAME} \
    --labels ubuntu,self-hosted,docker,kubectl \
    --work /tmp/_work"

# Install runner as a service
log_info "Installing runner service..."
cd "$RUNNER_DIR"
./svc.sh install "$RUNNER_USER"

# Start the service
log_info "Starting runner service..."
./svc.sh start

# Enable service to start on boot
systemctl enable actions.runner.*

log_info "Runner setup completed successfully!"
echo ""
log_info "Runner status:"
./svc.sh status
echo ""
log_info "Useful commands:"
echo "  Check status:  sudo $RUNNER_DIR/svc.sh status"
echo "  Start:        sudo $RUNNER_DIR/svc.sh start"
echo "  Stop:         sudo $RUNNER_DIR/svc.sh stop"
echo "  Restart:      sudo $RUNNER_DIR/svc.sh restart"
echo "  Uninstall:    sudo $RUNNER_DIR/svc.sh uninstall"
echo ""
log_warn "Don't forget to add these secrets to your organization:"
echo "  - KUBECONFIG (base64 encoded: cat ~/.kube/config | base64)"
