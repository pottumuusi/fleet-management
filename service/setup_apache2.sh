#!/bin/bash

set -e

# Support running with root user in a system that lacks sudo.
if [ -z $(which sudo 2> /dev/null) ] ; then
	SUDO=""
else
	SUDO="sudo"
fi

# Check if IPV6 is enabled in Linux
${SUDO} sysctl net.ipv6.conf.all.disable_ipv6

# Install firewall
${SUDO} apt install ufw

# Initial firewall configuration, keeping ssh connection intact
${SUDO} ufw default deny incoming
${SUDO} ufw default allow outgoing
${SUDO} ufw allow ssh
${SUDO} ufw enable

# Check for IPV6 support in firewall
grep IPV6 /etc/default/ufw

# For Apache, allow port 80, http
${SUDO} ufw allow http
${SUDO} ufw status

# Install Apache
${SUDO} apt install apache2

# Default to apache being off
${SUDO} systemctl disable apache2
systemctl status apache2

# Add web content for testing
${SUDO} mkdir /var/www/html/testing
${SUDO} sh -c "echo 'testing testing' > /var/www/html/testing/testing.txt"

echo -e "\n In a web browser, navigate to http://<IP of the server>/testing\n"
