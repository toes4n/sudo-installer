#!/bin/bash

# --- Configuration ---
SUDO_VERSION="1.9.17p2"
TARBALL="sudo-${SUDO_VERSION}.tar.gz"
DOWNLOAD_URL="https://www.sudo.ws/dist/${TARBALL}"
SOURCE_DIR="sudo-${SUDO_VERSION}"
INSTALL_PREFIX="/usr"
TEMP_DIR="/usr/local/src"

# --- Pre-check and Setup ---
echo "--- Starting sudo ${SUDO_VERSION} Installation Script ---"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

# Check /bin/make permissions (diagnose the permission issue)
echo "0. Diagnosing system..."
if [ -f /bin/make ] || [ -f /usr/bin/make ]; then
    echo "Make exists. Checking permissions..."
    ls -la /bin/make /usr/bin/make 2>/dev/null
    chmod +x /bin/make /usr/bin/make 2>/dev/null
fi

# Install necessary development dependencies for Alibaba Linux 3
echo "1. Installing Development Tools and Dependencies..."
echo "Updating yum cache..."
yum clean all
yum makecache

echo "Installing compiler and build tools..."
yum -y install gcc gcc-c++ make automake autoconf zlib-devel openssl-devel pam-devel git curl patch

# Wait for installation to complete
sleep 2

# Verify installations one by one
echo ""
echo "2. Verifying installation of build tools..."

if ! command -v gcc &> /dev/null; then
    echo "✗ ERROR: gcc not found after installation"
    echo "Attempting alternative installation..."
    yum -y install @development-tools
    sleep 2
    if ! command -v gcc &> /dev/null; then
        echo "FATAL: Cannot install gcc. Check your yum repositories."
        yum repolist
        exit 1
    fi
fi
echo "✓ GCC: $(gcc --version | head -n1)"

if ! command -v make &> /dev/null; then
    echo "✗ ERROR: make not found after installation"
    echo "Attempting direct make installation..."
    yum -y install make
    sleep 2
    if ! command -v make &> /dev/null; then
        echo "FATAL: Cannot install make."
        exit 1
    fi
fi
echo "✓ Make: $(make --version | head -n1)"

# Show which compiler will be used
echo "✓ Compiler path: $(which gcc)"
echo "✓ Make path: $(which make)"

# Update PATH to ensure tools are found
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Create source directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# --- Download and Extract ---
echo ""
echo "3. Downloading and extracting source code..."

# Remove old source if exists
if [ -d "$SOURCE_DIR" ]; then
    echo "Removing old source directory..."
    rm -rf "$SOURCE_DIR"
fi

if [ ! -f "$TARBALL" ]; then
    echo "Downloading sudo ${SUDO_VERSION}..."
    curl -L -O "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo "✗ ERROR: Failed to download sudo source tarball."
        exit 1
    fi
    echo "✓ Download complete"
fi

echo "Extracting source..."
tar -xzf "$TARBALL"
if [ $? -ne 0 ]; then
    echo "✗ ERROR: Failed to extract tarball."
    exit 1
fi
echo "✓ Extraction complete"

cd "$SOURCE_DIR" || exit 1

# --- Configure ---
echo ""
echo "4. Configuring build environment..."
echo "Current directory: $(pwd)"
echo "PATH: $PATH"

CC=$(which gcc) ./configure \
    --prefix="${INSTALL_PREFIX}" \
    --libexecdir="${INSTALL_PREFIX}/lib" \
    --with-secure-path \
    --with-env-editor \
    --with-passprompt="[sudo] password for %p: " \
    --docdir="${INSTALL_PREFIX}/share/doc/${SOURCE_DIR}" \
    --with-pam

if [ $? -ne 0 ]; then
    echo ""
    echo "✗ ERROR: Configuration failed."
    echo "Showing last 30 lines of config.log:"
    tail -n 30 config.log
    exit 1
fi
echo "✓ Configuration complete"

# --- Compile ---
echo ""
echo "5. Compiling code (This may take a few minutes)..."
$(which make) -j$(nproc)

if [ $? -ne 0 ]; then
    echo "✗ ERROR: Compilation failed."
    exit 1
fi
echo "✓ Compilation complete"

# --- Install ---
echo ""
echo "6. Installing (Overwriting system binaries)..."
$(which make) install

if [ $? -ne 0 ]; then
    echo "✗ ERROR: Installation failed."
    exit 1
fi
echo "✓ Installation complete"

# --- Refresh library cache ---
echo ""
echo "7. Updating system library cache..."
ldconfig

# --- Final Verification ---
echo ""
echo "8. Verifying Installation..."

# Force rehash to find new sudo binary
hash -r

# Check the version of the newly installed binary
NEW_VERSION=$(${INSTALL_PREFIX}/bin/sudo -V 2>/dev/null | head -n 1)

echo "Expected: Sudo version ${SUDO_VERSION}"
echo "Got: ${NEW_VERSION}"

if [[ "$NEW_VERSION" == *"${SUDO_VERSION}"* ]]; then
    echo "✓ SUCCESS! Sudo ${SUDO_VERSION} installed successfully."
else
    echo "✗ WARNING: Version mismatch detected."
    echo ""
    echo "Checking all sudo binaries on system:"
    which -a sudo
    /usr/bin/sudo -V | head -n1
    /usr/local/bin/sudo -V 2>/dev/null | head -n1
fi

echo ""
echo "--- Installation Complete ---"
sudo -V | head -n 1
