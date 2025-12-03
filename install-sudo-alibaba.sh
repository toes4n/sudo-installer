#!/bin/bash

# --- Configuration ---
SUDO_VERSION="1.9.17p2"
TARBALL="sudo-${SUDO_VERSION}.tar.gz"
DOWNLOAD_URL="https://www.sudo.ws/dist/${TARBALL}"
SOURCE_DIR="sudo-${SUDO_VERSION}"
INSTALL_PREFIX="/usr"
TEMP_DIR="/usr/local/src"

echo "--- Starting sudo ${SUDO_VERSION} Installation Script ---"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

# Install ALL required dependencies including PAM
echo "1. Installing Development Tools and Dependencies..."
yum update -y
yum -y install \
    gcc \
    gcc-c++ \
    make \
    automake \
    autoconf \
    zlib-devel \
    openssl-devel \
    pam-devel \
    git \
    curl \
    patch

# Verify critical packages
echo ""
echo "2. Verifying installations..."

if ! command -v gcc &> /dev/null; then
    echo "✗ ERROR: gcc not installed"
    exit 1
fi
echo "✓ GCC: $(gcc --version | head -n1)"

if ! rpm -q pam-devel &> /dev/null; then
    echo "✗ ERROR: pam-devel not installed"
    exit 1
fi
echo "✓ PAM development library installed"

# Set explicit paths
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

# Create and enter working directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Download and extract
echo ""
echo "3. Downloading and extracting source code..."

if [ -d "$SOURCE_DIR" ]; then
    echo "Removing old source directory..."
    rm -rf "$SOURCE_DIR"
fi

if [ ! -f "$TARBALL" ]; then
    curl -L -O "$DOWNLOAD_URL" || { echo "✗ Download failed"; exit 1; }
fi

tar -xzf "$TARBALL" || { echo "✗ Extraction failed"; exit 1; }
cd "$SOURCE_DIR" || exit 1

echo "✓ Source extracted to $(pwd)"

# Configure
echo ""
echo "4. Configuring build environment..."

./configure \
    CC="$CC" \
    --prefix="${INSTALL_PREFIX}" \
    --libexecdir="${INSTALL_PREFIX}/lib" \
    --with-secure-path \
    --with-env-editor \
    --with-passprompt="[sudo] password for %p: " \
    --docdir="${INSTALL_PREFIX}/share/doc/${SOURCE_DIR}" \
    --with-pam

if [ $? -ne 0 ]; then
    echo "✗ Configuration failed"
    echo ""
    echo "Checking PAM library location..."
    find /usr -name "libpam.so*" 2>/dev/null
    rpm -ql pam-devel | grep -E "\.so|\.h"
    exit 1
fi

echo "✓ Configuration successful"

# Compile
echo ""
echo "5. Compiling (this may take a few minutes)..."
make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "✗ Compilation failed"
    exit 1
fi

echo "✓ Compilation successful"

# Install
echo ""
echo "6. Installing..."
make install

if [ $? -ne 0 ]; then
    echo "✗ Installation failed"
    exit 1
fi

echo "✓ Installation successful"

# Update system
echo ""
echo "7. Updating system cache..."
ldconfig
hash -r

# Verify
echo ""
echo "8. Verifying installation..."
NEW_VERSION=$(/usr/bin/sudo -V 2>/dev/null | head -n 1)

echo "Expected: Sudo version ${SUDO_VERSION}"
echo "Installed: ${NEW_VERSION}"

if [[ "$NEW_VERSION" == *"${SUDO_VERSION}"* ]]; then
    echo ""
    echo "✓✓✓ SUCCESS! Sudo ${SUDO_VERSION} installed successfully ✓✓✓"
else
    echo ""
    echo "✗ Version mismatch detected"
    echo ""
    echo "Checking sudo binary locations:"
    which -a sudo
    ls -la /usr/bin/sudo /usr/local/bin/sudo 2>/dev/null
fi

echo ""
echo "--- Installation Complete ---"
sudo -V | head -n 1
