#!/bin/bash

set -e

# Update all packages
yum update -y

# Install Development Tools group and required packages
yum groupinstall "Development Tools" -y
yum install -y gcc gcc-c++ make pam-devel openssl-devel wget

# Go to /tmp directory
cd /tmp || exit 1

# Download sudo 1.9.17p2 source tarball
wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz

# Extract the tarball
tar -xzvf sudo-1.9.17p2.tar.gz

cd sudo-1.9.17p2 || exit 1

# Configure, build, and install sudo from source
./configure
make
make install

# Backup old sudo binary (usually /usr/bin/sudo)
if [ -f /usr/bin/sudo ]; then
    mv /usr/bin/sudo /usr/bin/sudo.old
fi

# Create symlinks for new sudo binary
ln -sf /usr/local/bin/sudo /usr/bin/sudo
ln -sf /usr/local/bin/sudo /bin/sudo

# Verify new sudo version
/usr/local/bin/sudo -V

echo "Sudo upgrade successfully."
