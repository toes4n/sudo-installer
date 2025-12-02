#!/bin/bash

set -e

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting sudo upgrade process on Rocky Linux...${NC}"

# Update packages
echo -e "${YELLOW}Updating system packages...${NC}"
dnf update -y

# Install Development Tools group and required packages
echo -e "${YELLOW}Installing development tools and dependencies...${NC}"
dnf groupinstall "Development Tools" -y
dnf install -y pam-devel openssl-devel wget

# Navigate to /tmp directory
cd /tmp || exit 1

# Download sudo 1.9.17p2 source tarball
echo -e "${YELLOW}Downloading sudo 1.9.17p2 source...${NC}"
wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz

# Extract the tarball
echo -e "${YELLOW}Extracting sudo source...${NC}"
tar -xzvf sudo-1.9.17p2.tar.gz

cd sudo-1.9.17p2 || exit 1

# Configure, build, and install sudo from source
echo -e "${YELLOW}Configuring sudo...${NC}"
./configure --prefix=/usr --libexecdir=/usr/lib --with-all-insults --with-env-editor

echo -e "${YELLOW}Building sudo...${NC}"
make

echo -e "${YELLOW}Installing sudo...${NC}"
make install

# Update shared library cache
echo -e "${YELLOW}Updating shared library cache...${NC}"
ldconfig

# Clear bash command hash table
hash -r

# Backup old sudo binary if it exists in different location
if [ -f /usr/bin/sudo.old ]; then
    echo -e "${YELLOW}Previous backup found, removing old backup...${NC}"
    rm -f /usr/bin/sudo.old
fi

# Verify sudo installation
echo -e "${YELLOW}Verifying sudo installation...${NC}"
/usr/bin/sudo -V | head -n 1

# Test sudo functionality
echo -e "${YELLOW}Testing sudo functionality...${NC}"
/usr/bin/sudo echo "Sudo is working correctly!"

# Cleanup
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
cd /tmp
rm -rf sudo-1.9.17p2 sudo-1.9.17p2.tar.gz

echo -e "${GREEN}✓ Sudo upgrade completed successfully on Rocky Linux!${NC}"
echo -e "${GREEN}Installed version:${NC}"
/usr/bin/sudo -V | head -n 1
