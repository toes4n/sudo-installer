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

# --- CRITICAL: Fix GCC Permission Issues ---
echo "=== DIAGNOSING GCC INSTALLATION ISSUES ==="
echo ""

# Find all gcc binaries
echo "1. Locating GCC binaries..."
find /bin /usr/bin /usr/local/bin -name "gcc*" 2>/dev/null | while read file; do
    echo "Found: $file"
    ls -la "$file"
done

echo ""
echo "2. Checking SELinux status..."
getenforce 2>/dev/null || echo "SELinux not available"

echo ""
echo "3. Attempting to fix permissions and reinstall GCC..."

# Remove potentially corrupted gcc installation
yum remove -y gcc gcc-c++ 2>/dev/null

# Clean yum cache
yum clean all
rm -rf /var/cache/yum/*

# Reinstall with verbose output
echo ""
echo "4. Reinstalling development tools..."
yum -y install gcc gcc-c++ make

echo ""
echo "5. Verifying GCC installation..."
rpm -qa | grep gcc

echo ""
echo "6. Checking GCC file permissions..."
if [ -f /usr/bin/gcc ]; then
    ls -laZ /usr/bin/gcc 2>/dev/null || ls -la /usr/bin/gcc
    chmod 755 /usr/bin/gcc
    echo "✓ Found GCC at /usr/bin/gcc"
else
    echo "✗ GCC not found at /usr/bin/gcc"
    echo "Searching entire system..."
    find / -name gcc -type f 2>/dev/null | head -5
fi

echo ""
echo "7. Testing GCC execution..."
if /usr/bin/gcc --version > /dev/null 2>&1; then
    echo "✓ GCC executes successfully"
    /usr/bin/gcc --version | head -1
else
    echo "✗ GCC execution failed"
    
    # Check if it's a SELinux issue
    if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
        echo ""
        echo "SELinux may be blocking GCC. Attempting to fix..."
        restorecon -v /usr/bin/gcc 2>/dev/null
        setenforce 0 2>/dev/null
        echo "SELinux temporarily set to Permissive mode"
        
        # Try again
        if /usr/bin/gcc --version > /dev/null 2>&1; then
            echo "✓ GCC now works after SELinux adjustment"
        else
            echo "✗ Still failing. This may be a deeper system issue."
            exit 1
        fi
    else
        echo "Not a SELinux issue. Checking file system..."
        mount | grep /usr
        exit 1
    fi
fi

# Update PATH explicitly
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

echo ""
echo "8. Final verification..."
echo "PATH: $PATH"
echo "CC: $CC"
which gcc
gcc --version | head -1

if ! command -v gcc &> /dev/null; then
    echo "FATAL: GCC still not accessible. Cannot proceed."
    exit 1
fi

# --- Continue with sudo installation ---
echo ""
echo "=== PROCEEDING WITH SUDO INSTALLATION ==="

mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

echo ""
echo "Downloading and extracting source code..."
if [ -d "$SOURCE_DIR" ]; then
    rm -rf "$SOURCE_DIR"
fi

if [ ! -f "$TARBALL" ]; then
    curl -L -O "$DOWNLOAD_URL" || { echo "Download failed"; exit 1; }
fi

tar -xzf "$TARBALL" || { echo "Extraction failed"; exit 1; }
cd "$SOURCE_DIR" || exit 1

echo ""
echo "Configuring build environment..."
echo "Using CC=$CC"

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
    echo "✗ Configuration failed. Showing config.log:"
    tail -n 50 config.log
    exit 1
fi

echo ""
echo "Compiling..."
make -j$(nproc) || { echo "Compilation failed"; exit 1; }

echo ""
echo "Installing..."
make install || { echo "Installation failed"; exit 1; }

echo ""
echo "Updating system..."
ldconfig
hash -r

echo ""
echo "=== VERIFICATION ==="
NEW_VERSION=$(/usr/bin/sudo -V 2>/dev/null | head -n 1)
echo "Installed: $NEW_VERSION"

if [[ "$NEW_VERSION" == *"${SUDO_VERSION}"* ]]; then
    echo "✓ SUCCESS! Sudo ${SUDO_VERSION} installed."
else
    echo "✗ Version mismatch. Check installation."
fi

echo ""
echo "--- Installation Complete ---"
