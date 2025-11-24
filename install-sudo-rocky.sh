sudo dnf groupinstall 'Development Tools' -y
sudo dnf install pam-devel openssl-devel wget -y

cd /tmp
wget https://www.sudo.ws/dist/sudo-1.9.17p2.tar.gz
tar -xzvf sudo-1.9.17p2.tar.gz
cd sudo-1.9.17p2

./configure
make
sudo make install

sudo mv /usr/bin/sudo /usr/bin/sudo.old
sudo ln -s /usr/local/bin/sudo /usr/bin/sudo
sudo -V

