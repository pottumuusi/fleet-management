#!/bin/bash

sudo apt install nix-bin

# https://wiki.archlinux.org/title/Nix
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update

sudo usermod -aG nix-users ${USER}

echo "The groups of user ${USER} were modified. Please logout and login."
