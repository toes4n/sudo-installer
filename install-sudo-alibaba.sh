#!/bin/bash

SUDO_VERSION="1.9.17p2"
TEMP_DIR="/usr/local/src"
chmod 755 /usr/bin/gcc
# Ensure GCC works
if ! /usr/bin/gcc --version &>/dev/null; then
    echo "ERROR: GCC still not working. "
    exit 1
fi

# Set explicit paths
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

cd "$TEMP_DIR"

# Download and extract
curl -O "https://www.sudo.ws/dist/sudo-${SUDO_VERSION}.tar.gz"
tar -xzf "sudo-${SUDO_VERSION}.tar.gz"
cd "sudo-${SUDO_VERSION}"

# Configure with explicit compiler
./configure \
    CC="$CC" \
    CXX="$CXX" \
    --prefix=/usr \
    --with-pam

# Build and install
make -j$(nproc)
make install

# Verify
ldconfig
hash -r
/usr/bin/sudo -V | head -1
