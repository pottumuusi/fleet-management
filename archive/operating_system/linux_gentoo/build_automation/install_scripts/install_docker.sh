#!/bin/bash

set -e

echo "Next, running commands via sudo"

if [ -n "$(which docker)" ] ; then
	echo Docker is already installed. Exiting...
	exit 1
fi

# Prerequisite packages
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# GPG key of docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo -e "\n\nPrinting added key\n=================="
sudo apt-key fingerprint 0EBFCD88
read -p "Press enter to continue"

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "For test, running docker hello world"
sudo docker run hello-world
