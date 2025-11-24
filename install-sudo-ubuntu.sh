#!/bin/bash

# Script to compile and install sudo 1.9.17p2 from source
# Requires root privileges

set -euo pipefail
IFS=$'\n\t'

# Configuration
SUDO_VERSION="1.9.17p2"
SUDO_URL="https://www.sudo.ws/dist/sudo-${SUDO_VERSION}.tar.gz"
BUILD_DIR="/tmp"
LOG_FILE="/var/log/sudo_install_$(date +%Y%m%d_%H%M%S).log"

# Logging function
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Error handler
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root"
fi

log "INFO" "Starting sudo ${SUDO_VERSION} installation"

# Update package lists
log "INFO" "Updating package lists"
apt update || error_exit "Failed to update package lists"

# Install dependencies
log "INFO" "Installing build dependencies"
apt install build-essential gcc-13 g++-13 make libpam0g-dev libssl-dev wget -y || error_exit "Failed to install dependencies"

# Set proper permissions for build tools
log "INFO" "Setting permissions for build tools"
chmod 755 /usr/bin/make
chmod 755 /usr/bin/x86_64-linux-gnu-* 2>/dev/null || true

# Verify build tools
log "INFO" "Verifying build tools"
gcc --version >> "$LOG_FILE" || error_exit "GCC not available"
make --version >> "$LOG_FILE" || error_exit "Make not available"

# Download sudo source
log "INFO" "Downloading sudo ${SUDO_VERSION} source"
cd "$BUILD_DIR" || error_exit "Failed to change to build directory"
wget "$SUDO_URL" || error_exit "Failed to download sudo source"

# Extract source
log "INFO" "Extracting sudo source"
tar -xzvf "sudo-${SUDO_VERSION}.tar.gz" || error_exit "Failed to extract sudo source"
cd "sudo-${SUDO_VERSION}" || error_exit "Failed to change to sudo source directory"

# Configure
log "INFO" "Configuring sudo build"
./configure >> "$LOG_FILE" 2>&1 || error_exit "Configure failed"

# Compile
log "INFO" "Compiling sudo (this may take a few minutes)"
make >> "$LOG_FILE" 2>&1 || error_exit "Compilation failed"

# Install
log "INFO" "Installing sudo to /usr/local/bin"
make install >> "$LOG_FILE" 2>&1 || error_exit "Installation failed"

# Backup old sudo and create symlink
log "INFO" "Backing up old sudo and creating symlink"
if [[ -f /usr/bin/sudo ]]; then
    mv /usr/bin/sudo /usr/bin/sudo.old || error_exit "Failed to backup old sudo"
    log "INFO" "Old sudo backed up to /usr/bin/sudo.old"
fi

ln -sf /usr/local/bin/sudo /usr/bin/sudo || error_exit "Failed to create symlink"

# Verify installation
log "INFO" "Verifying sudo installation"
SUDO_INSTALLED_VERSION=$(/usr/bin/sudo -V | head -n1)
log "INFO" "Installed: $SUDO_INSTALLED_VERSION"

# Cleanup
log "INFO" "Cleaning up temporary files"
cd /tmp
rm -rf "sudo-${SUDO_VERSION}" "sudo-${SUDO_VERSION}.tar.gz"

log "INFO" "Sudo ${SUDO_VERSION} installation completed successfully"
log "INFO" "Log file saved to: $LOG_FILE"

# Display version
sudo -V
