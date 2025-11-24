#!/bin/bash

set -e

# Update all packages
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

# Go to /tmp directory
cd /tmp || exit 1

# Download sudo 1.9.17p2 source tarball
wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz

# Extract the tarball
tar -xzvf sudo-1.9.17p2.tar.gz

cd sudo-1.9.17p2 || exit 1

# Configure, make, and install sudo
./configure
make
sudo make install

# Backup existing sudo binary if it exists
if [ -f /usr/bin/sudo ] && [ ! -L /usr/bin/sudo ]; then
    sudo mv /usr/bin/sudo /usr/bin/sudo.old
fi

# Create symlink to new sudo binary in /usr/bin
sudo ln -sf /usr/local/bin/sudo /usr/bin/sudo

# Create symlink in /bin for compatibility if it doesn't exist
if [ ! -L /bin/sudo ]; then
    sudo ln -sf /usr/local/bin/sudo /bin/sudo
fi

# Verify sudo installation
sudo -V

echo "Sudo 1.9.17p2 installation completed successfully."
