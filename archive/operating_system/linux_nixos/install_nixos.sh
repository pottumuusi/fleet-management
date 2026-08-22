#/bin/bash

set -ex

username="username"
volume_group="vg01"
boot_partition="/dev/nvme0n1p2"
swap_partition="/dev/nvme0n1p6"
nixos_root_name="dom0_nixos"

config_repo_top="${HOME}/config/useful-files"
nixos_saved_config="${config_repo_top}/config/nixos/configuration.nix"
alsa_config="${config_repo_top}/config/alsa/asound.conf"
i3_config="${config_repo_top}/config/i3/.config/i3/config"
i3status_config="${config_repo_top}/config/i3status/.config/i3status/config"
tmux_config="${config_repo_top}/config/tmux/oh_my_tmux/.tmux.conf"
tmux_config_local="${config_repo_top}/config/tmux/oh_my_tmux/.tmux.conf.local"
vimrc="${config_repo_top}/config/vim/.vimrc"

# loadkeys fi
# nix-env -i wget
# nix-env -i git

#### Activate LVM volumes in volume group
vgchange -a y ${volume_group}

swapon ${swap_partition}

mount /dev/${volume_group}/${nixos_root_name} /mnt
mkdir -p /mnt/boot
mount ${boot_partition} /mnt/boot

nixos-generate-config --root /mnt
cp ${nixos_saved_config} /mnt/etc/nixos/configuration.nix
sed -i 's/username/'"$username"'/g' /mnt/etc/nixos/configuration.nix

nixos-install

mkdir -p /mnt/home/${username}/.config/i3
mkdir -p /mnt/home/${username}/.config/i3status

cp ${alsa_config} /mnt/etc/
cp ${i3_config} /mnt/home/${username}/.config/i3/
cp ${i3status_config} /mnt/home/${username}/.config/i3status/
cp ${tmux_config} /mnt/home/${username}/
cp ${tmux_config_local} /mnt/home/${username}/
cp ${vimrc} /mnt/home/${username}/
