#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

SUDO_VERSION="1.9.17p2"
DOWNLOAD_URL="https://www.sudo.ws/dist/sudo-${SUDO_VERSION}.tar.gz"
INSTALL_PATH="/usr/local/bin/sudo"
SYSTEM_BIN_PATH="/usr/bin/sudo"
TEMP_DIR="/tmp/sudo-source"

echo "--- Starting Sudo ${SUDO_VERSION} Compilation and Installation ---"

# 1. Update packages and install dependencies
echo "1. Installing dependencies..."
if command -v dnf &> /dev/null; then
    sudo dnf update -y
    sudo dnf groupinstall "Development Tools" -y
    sudo dnf install -y pam-devel openssl-devel wget
elif command -v yum &> /dev/null; then
    sudo yum update -y
    sudo yum groupinstall "Development Tools" -y
    sudo yum install -y pam-devel openssl-devel wget
else
    echo "Neither yum nor dnf found. Exiting."
    exit 1
fi
echo "Dependencies installed."

# 2. Prepare temporary directory and download source
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || { echo "Failed to cd to temporary directory"; exit 1; }
echo "2. Downloading source from ${DOWNLOAD_URL}..."
wget -q "$DOWNLOAD_URL"

# 3. Extract and change directory
tar -xzvf "sudo-${SUDO_VERSION}.tar.gz"
cd "sudo-${SUDO_VERSION}" || { echo "Failed to cd to sudo source directory"; exit 1; }
echo "Source extracted."

# 4. Configure, build, and install sudo from source
echo "3. Configuring, building, and installing..."
./configure
make
# NOTE: This step relies on the OLD sudo working.
sudo make install

# --- CRITICAL CHECK ADDED HERE ---
# 5. Verify the new binary exists at the installation target
if [ ! -f "$INSTALL_PATH" ]; then
    echo "FATAL ERROR: New sudo binary NOT found at $INSTALL_PATH after 'make install'."
    echo "Please check the output of 'make install' for errors or configuration issues."
    exit 1
fi
echo "New binary successfully installed at $INSTALL_PATH."

# 6. Manage system binary and symlink
# Move original sudo binary if it exists and is NOT a symlink
if [ -f "$SYSTEM_BIN_PATH" ] && [ ! -L "$SYSTEM_BIN_PATH" ]; then
    echo "4. Backing up original sudo binary: ${SYSTEM_BIN_PATH} to ${SYSTEM_BIN_PATH}.old"
    sudo mv "$SYSTEM_BIN_PATH" "${SYSTEM_BIN_PATH}.old"
elif [ -L "$SYSTEM_BIN_PATH" ]; then
    echo "4. Original sudo binary is a symlink. Replacing link target."
fi

# Create symlink /usr/bin/sudo pointing to /usr/local/bin/sudo
echo "5. Creating/updating symlink: ${SYSTEM_BIN_PATH} -> ${INSTALL_PATH}"
sudo ln -sf "$INSTALL_PATH" "$SYSTEM_BIN_PATH"

# Ensure the new sudo binary is executable
echo "6. Ensuring binary is executable."
sudo chmod 4755 "$INSTALL_PATH"

# 7. Test new sudo version
echo "7. Testing new sudo binary using the explicit path:"
# Use the explicit, new path for the version check
"$INSTALL_PATH" -V

echo "--- Sudo ${SUDO_VERSION} installation completed successfully. ---"

# Cleanup
cd /
rm -rf "$TEMP_DIR"
echo "Temporary files cleaned up."
