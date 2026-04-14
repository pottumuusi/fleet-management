#!/bin/bash

# Check if IPV6 is enabled in Linux
sudo sysctl net.ipv6.conf.all.disable_ipv6

# Install firewall
sudo apt install ufw

# Initial firewall configuration, keeping ssh connection intact
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Check for IPV6 support in firewall
grep IPV6 /etc/default/ufw

# For Apache, allow port 80, http
sudo ufw allow http
sudo ufw status

# Install Apache
sudo apt install apache2

# Default to apache being off
sudo systemctl disable apache2
systemctl status apache2

# Add web content for testing
sudo mkdir /var/www/html/testing
sudo sh -c "echo 'testing testing' > /var/www/html/testing/testing.txt"

echo -e "\n In a web browser, navigate to http://<IP of the server>/testing\n"
