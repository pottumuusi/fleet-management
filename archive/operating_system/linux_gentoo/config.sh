#!/bin/bash

# Select what to setup
readonly cfg_should_setup_partitions="TRUE"

readonly cfg_should_setup_portage="TRUE"
readonly cfg_should_setup_timezone="TRUE"
readonly cfg_should_setup_locale="TRUE"
readonly cfg_should_setup_kernel="TRUE"
readonly cfg_should_setup_lvm="FALSE"
readonly cfg_should_setup_new_system="TRUE"
readonly cfg_should_setup_bootloader="TRUE"
readonly cfg_should_setup_packages="TRUE"

readonly cfg_set_efi64_grub_platform="FALSE"
readonly cfg_write_partition_using_sfdisk="TRUE"
readonly cfg_write_partition_using_sgdisk="FALSE"
readonly cfg_setup_home_partition="FALSE"
readonly cfg_confirm_config="TRUE"
readonly cfg_shutdown_when_done="TRUE"

# Will create grub config regardless of this option
readonly cfg_install_grub_to_disk="TRUE"

readonly main_block_device="/dev/sda"
readonly mountpoint_root="/mnt/gentoo"
readonly mountpoint_home="${mountpoint_root}/home"
readonly mountpoint_ram="${mountpoint_root}/mnt_ram"
readonly chroot_mountpoint_ram="/mnt_ram"

# Parse stage3 tar name from webpage.
readonly frozen_stage3_release_dir="https://mirror.netcologne.de/gentoo/releases/amd64/autobuilds/current-stage3-amd64/"
readonly stage3_tar="$(curl ${frozen_stage3_release_dir}	\
	| grep stage3-amd64					\
	| grep tar						\
	| grep -v multilib					\
	| grep -v systemd					\
	| grep -v -e CONTENTS -e DIGESTS			\
	| cut -d ">" -f 2					\
	| cut -d "<" -f 1)"

readonly gentoo_config="${script_root}/gentoo_config"

readonly make_conf="${gentoo_config}/make.conf"

readonly lv_name_root="root2"
readonly lv_name_home="home2"
readonly lv_name_swap="swap"
readonly volgroup_name="vg01"
readonly lvm_root_partition_dev="/dev/${volgroup_name}/${lv_name_root}"
readonly lvm_home_partition_dev="/dev/${volgroup_name}/${lv_name_home}"
readonly lvm_swap_partition_dev="/dev/${volgroup_name}/${lv_name_swap}"
temp_root_partition_dev="${main_block_device}4"
temp_boot_partition_dev="${main_block_device}2"
temp_home_partition_dev="${main_block_device}5"
temp_swap_partition_dev="${main_block_device}3"

if [ "TRUE" == "${cfg_should_setup_lvm}" ] ; then
	temp_root_partition_dev="${lvm_root_partition_dev}"
	temp_home_partition_dev="${lvm_home_partition_dev}"
	temp_swap_partition_dev="${lvm_swap_partition_dev}"
fi

readonly root_partition_dev="${temp_root_partition_dev}"
readonly home_partition_dev="${temp_home_partition_dev}"
readonly swap_partition_dev="${temp_swap_partition_dev}"
readonly boot_partition_dev="${temp_boot_partition_dev}"
readonly lvm_partition_dev="${main_block_device}2"
unset temp_root_partition_dev
unset temp_home_partition_dev
unset temp_swap_partition_dev
unset temp_boot_partition_dev

readonly saved_partition_table="${gentoo_config}/saved_partition_table"
readonly gpt_partition_backup_file="sgdisk-sda.bin"

readonly root_size="14G" # root size when using LVM, variable name is misleading
readonly home_size="9995M"

readonly opt_pre_chroot="--pre-chroot"
readonly opt_chroot="--chroot"
readonly opt_full_install="--full"

# Intended to be called after having chrooted to new environment.
readonly opt_post_chroot="--post-chroot"

readonly kernel_sources_dir="/usr/src/linux"
readonly root_password_file_in_ram="${mountpoint_ram}/rootpass.txt"
readonly chroot_root_password_file_in_ram="${chroot_mountpoint_ram}/rootpass.txt"

readonly new_hostname="my_hostname"
readonly inet_if="enp1s0" # TODO read this from a command, instead of hardcoding
# readonly inet_if="wlp3s0" # TODO read this from a command, instead of hardcoding

cached_root_password=""

function dump_config() {
	set +x

	echo ""
	echo "cfg_should_setup_partitions=${cfg_should_setup_partitions}"
	echo "cfg_should_setup_portage=${cfg_should_setup_portage}"
	echo "cfg_should_setup_timezone=${cfg_should_setup_timezone}"
	echo "cfg_should_setup_locale=${cfg_should_setup_locale}"
	echo "cfg_should_setup_kernel=${cfg_should_setup_kernel}"
	echo "cfg_should_setup_lvm=${cfg_should_setup_lvm}"
	echo "cfg_should_setup_new_system=${cfg_should_setup_new_system}"
	echo "cfg_should_setup_bootloader=${cfg_should_setup_bootloader}"
	echo "cfg_should_setup_packages=${cfg_should_setup_packages}"
	echo "cfg_install_grub_to_disk=${cfg_install_grub_to_disk}"
	echo "cfg_set_efi64_grub_platform=${cfg_set_efi64_grub_platform}"
	echo "cfg_write_partition_using_sfdisk=${cfg_write_partition_using_sfdisk}"
	echo "cfg_write_partition_using_sgdisk=${cfg_write_partition_using_sgdisk}"
	echo "cfg_setup_home_partition=${cfg_setup_home_partition}"
	echo "cfg_confirm_config=${cfg_confirm_config}"
	echo "cfg_shutdown_when_done=${cfg_shutdown_when_done}"
	echo ""
	echo "root_partition_dev=${root_partition_dev}"
	echo "home_partition_dev=${home_partition_dev}"
	echo "swap_partition_dev=${swap_partition_dev}"
	echo "boot_partition_dev=${boot_partition_dev}"
	if [ "TRUE" = "${cfg_should_setup_lvm}" ] ; then
		echo lvm_partition_dev="${lvm_partition_dev}"
	fi
	echo "main_block_device=${main_block_device}"
	echo "mountpoint_root=${mountpoint_root}"
	echo "mountpoint_home=${mountpoint_home}"
	echo "mountpoint_ram=${mountpoint_ram}"
	echo "stage3_tar=${stage3_tar}"
	echo ""

	set -x
}

function dump_config_and_wait_for_enter() {
	dump_config

	read -p "Proceed to install? [y/n]: " ans

	if [ "y" != "${ans}" -a "Y" != "${ans}" ] ; then
		echo "Stopping..."
		exit
	fi
}
