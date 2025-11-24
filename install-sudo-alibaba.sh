#!/bin/bash

set -e

# Update all packages and install development tools and dependencies
if command -v dnf &> /dev/null; then
    sudo dnf update -y
    sudo dnf groupinstall "Development Tools" -y
    sudo dnf install -y pam-devel openssl-devel wget
elif command -v yum &> /dev/null; then
    sudo yum update -y
    sudo yum groupinstall "Development Tools" -y
    sudo yum install -y pam-devel openssl-devel wget
else
    echo "Neither yum nor dnf. Exiting."
    exit 1
fi

# Change to /tmp directory
cd /tmp || exit 1

# Download sudo 1.9.17p2 source tarball
wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz

# Extract the downloaded tarball
tar -xzvf sudo-1.9.17p2.tar.gz

cd sudo-1.9.17p2 || exit 1

# Configure, build, and install sudo from source
./configure
make
sudo make install

# Ensure /bin/sudo and /usr/bin/sudo point to new sudo binary
if [ -f /usr/bin/sudo ] && [ ! -L /usr/bin/sudo ]; then
    sudo mv /usr/bin/sudo /usr/bin/sudo.old
fi
sudo ln -sf /usr/local/bin/sudo /usr/bin/sudo
sudo ln -sf /usr/local/bin/sudo /bin/sudo

# Now it is safe to run sudo commands
sudo -V


echo "Sudo 1.9.17p2 installation completed successfully."
