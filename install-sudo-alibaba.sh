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

# Install necessary development dependencies for Alibaba Linux 3
echo "1. Installing Development Tools and Dependencies..."
yum update -y
yum -y install gcc gcc-c++ make zlib-devel openssl-devel pam-devel git curl

# Verify GCC installation
if ! command -v gcc &> /dev/null; then
    echo "Error: gcc installation failed. Cannot proceed."
    exit 1
fi
echo "✓ GCC installed successfully: $(gcc --version | head -n1)"

# Create source directory and move into it
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# --- Download and Extract ---
echo "2. Downloading and extracting source code..."
if [ ! -f "$TARBALL" ]; then
    curl -O "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download sudo source tarball."
        exit 1
    fi
fi

tar -xzf "$TARBALL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to extract tarball."
    exit 1
fi

cd "$SOURCE_DIR"

# --- Configure ---
echo "3. Configuring build environment..."
./configure \
    --prefix="${INSTALL_PREFIX}" \
    --libexecdir="${INSTALL_PREFIX}/lib" \
    --with-secure-path \
    --with-env-editor \
    --with-passprompt="[sudo] password for %p: " \
    --docdir="${INSTALL_PREFIX}/share/doc/${SOURCE_DIR}" \
    --with-pam

if [ $? -ne 0 ]; then
    echo "Error: Configuration failed. Check config.log for details."
    exit 1
fi

# --- Compile and Install ---
echo "4. Compiling code (This may take a few minutes)..."
make

if [ $? -ne 0 ]; then
    echo "Error: Compilation failed."
    exit 1
fi

echo "5. Installing (Overwriting system binaries)..."
make install

if [ $? -ne 0 ]; then
    echo "Error: Installation failed."
    exit 1
fi

# --- Final Verification ---
echo "6. Verifying Installation..."

# Check the version of the newly installed binary
NEW_VERSION=$(${INSTALL_PREFIX}/bin/sudo -V 2>/dev/null | head -n 1)

if [[ "$NEW_VERSION" == *"Sudo version ${SUDO_VERSION}"* ]]; then
    echo "✓ Success! ${NEW_VERSION} installed successfully."
else
    echo "✗ Warning: Verification shows unexpected version."
    echo "Expected: Sudo version ${SUDO_VERSION}"
    echo "Got: ${NEW_VERSION}"
fi

echo "--- Installation Complete ---"
sudo -V | head -n 1
