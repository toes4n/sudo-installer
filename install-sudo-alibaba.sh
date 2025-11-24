#!/bin/bash

set -e

# Update all packages
sudo dnf update -y

# Install Development Tools group and required packages
sudo dnf groupinstall "Development Tools" -y
sudo dnf install -y pam-devel openssl-devel wget

# Navigate to /tmp directory
cd /tmp || exit 1

# Download sudo 1.9.17p2 source tarball
wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz

# Extract the tarball
tar -xzvf sudo-1.9.17p2.tar.gz

cd sudo-1.9.17p2 || exit 1

# Configure, build, and install sudo from source
./configure
make
sudo make install

# Backup old sudo binary if it exists
if [ -f /usr/bin/sudo ]; then
    sudo mv /usr/bin/sudo /usr/bin/sudo.old
fi

# Create symlink to new sudo binary
sudo ln -sf /usr/local/bin/sudo /usr/bin/sudo

# Create symlink in /bin for compatibility (optional)
if [ ! -L /bin/sudo ]; then
    sudo ln -sf /usr/local/bin/sudo /bin/sudo
fi

# Verify sudo installation
sudo -V

echo "Sudo Upgrade successfully on Alibaba Cloud Linux 3."
