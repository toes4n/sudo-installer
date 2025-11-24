#!/bin/bash

# --- Configuration ---
SUDO_VERSION="1.9.17p2"
TARBALL="sudo-${SUDO_VERSION}.tar.gz"
DOWNLOAD_URL="https://www.sudo.ws/dist/${TARBALL}"
SOURCE_DIR="sudo-${SUDO_VERSION}"
INSTALL_PREFIX="/usr" # Install to the standard /usr location
TEMP_DIR="/usr/local/src" # Directory for source compilation

# --- Pre-check and Setup ---
echo "--- Starting sudo ${SUDO_VERSION} Installation Script ---"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

# Install necessary development dependencies for Alibaba OS / CentOS / RHEL
echo "1. Installing Development Tools and Dependencies..."
# Using 'yum' for package management common to Alibaba/CentOS
yum -y groupinstall "Development Tools" > /dev/null 2>&1
yum -y install zlib-devel openssl-devel pam-devel git curl > /dev/null 2>&1

# Create source directory and move into it
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# --- Download and Extract ---
echo "2. Downloading and extracting source code..."
if [ ! -f "$TARBALL" ]; then
    curl -O "$DOWNLOAD_URL"
fi
tar -xvzf "$TARBALL"
cd "$SOURCE_DIR"

# --- Configure ---
echo "3. Configuring build environment..."
# Note: Using --prefix=/usr to overwrite the system binary path directly
./configure \
    --prefix="${INSTALL_PREFIX}" \
    --libexecdir="${INSTALL_PREFIX}/lib" \
    --with-secure-path \
    --with-env-editor \
    --with-passprompt="[sudo] password for %p: " \
    --docdir="${INSTALL_PREFIX}/share/doc/${SOURCE_DIR}" \
    --with-pam

# --- Compile and Install ---
echo "4. Compiling code (This may take a few minutes)..."
make

echo "5. Installing (Overwriting system binaries)..."
make install

# --- Final Verification ---
echo "6. Verifying Installation..."

# Check the version of the newly installed binary
NEW_VERSION=$(${INSTALL_PREFIX}/bin/sudo -V 2>/dev/null | head -n 1)

if [[ "$NEW_VERSION" == *"Sudo version ${SUDO_VERSION}"* ]]; then
    echo "✅ Success! ${NEW_VERSION} installed successfully."
else
    echo "❌ Error: Verification failed. The installed version is not ${SUDO_VERSION}."
    echo "Installed version output: ${NEW_VERSION}"
fi

echo "--- Installation Complete ---"
