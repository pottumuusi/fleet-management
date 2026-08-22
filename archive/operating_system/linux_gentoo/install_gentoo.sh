#!/bin/bash

set -ex

cd $(dirname $0)
script_root="$(pwd)"

source util.sh
source config.sh

readonly DISABLED="TRUE"

function process_args() {
	for opt in "$@" ; do
		echo opt is: $opt

		if [ "${opt_full_install}" = "$opt" ] ; then
			readonly is_pre_chroot_install="TRUE"
			readonly call_post_chroot_install="TRUE"
			continue
		fi

		if [ "${opt_chroot}" = "$opt" ] ; then
			readonly call_post_chroot_install="TRUE"
			continue
		fi

		if [ "${opt_post_chroot}" = "$opt" ] ; then
			readonly is_post_chroot_install="TRUE"
			continue
		fi

		if [ "${opt_pre_chroot}" = "$opt" ] ; then
			readonly is_pre_chroot_install="TRUE"
			continue
		fi

		error_exit "Unknown program argument: $opt"
	done

	if [ "TRUE" = "${is_pre_chroot_install}" -a "TRUE" = "${is_post_chroot_install}" ] ; then
		error_exit "Please choose either --pre-chroot or ${opt_post_chroot} as program argument. Not both."
	fi
}

function import_gentoo_gpg_key() {
	if [ "TRUE" != "${DISABLED}" ] ; then
		# Was not able to connect to sks-keyservers.net
		gpg --keyserver hkps://hkps.pool.sks-keyservers.net --recv-keys 0xBB572E0E2D182910
	fi
	wget -O- https://gentoo.org/.well-known/openpgpkey/hu/wtktzo4gyuhzu8a4z5fdj3fgmr1u6tob?l=releng | gpg --import
}

function setup_date_and_time() {
	print_header "SETTING DATE AND TIME"
	if [ "TRUE" != "${DISABLED}" ] ; then
		emerge net-misc/ntp
		ntpd -q -g # TODO test that works. Time may be correct out of the box
	fi
}

function maybe_mount_partitions() {
	print_header "MOUNTING PARTITIONS"

	if [ "TRUE" != "$(is_mounted "${mountpoint_root}")" ] ; then
		mount ${root_partition_dev} ${mountpoint_root}
	fi

	if [ ! -d "${mountpoint_root}/boot" ] ; then
		mkdir ${mountpoint_root}/boot
	fi

	if [ "TRUE" != "$(is_mounted "${mountpoint_root}/boot")" ] ; then
		mount ${boot_partition_dev} ${mountpoint_root}/boot
	fi

	if [ ! -d "${mountpoint_home}" ] ; then
		mkdir ${mountpoint_home}
	fi

	if [ "TRUE" = "${cfg_setup_home_partition}" ] ; then
		if [ "TRUE" != "$(is_mounted "${mountpoint_home}")" ] ; then
			mount ${home_partition_dev} ${mountpoint_home}
		fi
	fi

	if [ ! -d "${mountpoint_ram}" ] ; then
		mkdir ${mountpoint_ram}
	fi

	if [ "TRUE" != "$(is_mounted ${mountpoint_ram})" ] ; then
		mount -t tmpfs none -o size=100 ${mountpoint_ram}
	fi
}

function store_root_password_to_ram() {
	set +x
	echo ""
	read -s -p "Please enter root password to set at the end of install: " cached_root_password
	echo ""
	read -s -p "Please re-enter root password to set at the end of install: " cached_root_password_verification

	if [ "${cached_root_password}" != "${cached_root_password_verification}" ] ; then
		error_exit "Entered passwords do not match"
	fi

	set -x
}

function store_root_password_to_file_in_ram() {
	echo "${cached_root_password}" > ${root_password_file_in_ram}
}

function maybe_mount_pseudofilesystems() {
	print_header "MOUNTING PSEUDOFILESYSTEMS"

	if [ "TRUE" != "$(is_mounted "${mountpoint_root}/proc")" ] ; then
		mount --types proc /proc ${mountpoint_root}/proc
	fi

	if [ "TRUE" != "$(is_mounted "${mountpoint_root}/sys")" ] ; then
		mount --rbind /sys ${mountpoint_root}/sys
		mount --make-rslave ${mountpoint_root}/sys
	fi

	if [ "TRUE" != "$(is_mounted "${mountpoint_root}/dev")" ] ; then
		mount --rbind /dev ${mountpoint_root}/dev
		mount --make-rslave ${mountpoint_root}/dev
	fi
}

function setup_partitions() {
	print_header "PARTITIONING"

	if [ "TRUE" = "${cfg_write_partition_using_sfdisk}" -a "TRUE" = "${cfg_write_partition_using_sgdisk}" ] ; then
		error_exit "Config tells to write partition using sfdisk and sgdisk. Expecting only one of these to be chosen."
	fi

	if [ "TRUE" = "${cfg_write_partition_using_sfdisk}" ] ; then
		sfdisk --wipe always ${main_block_device} < ${saved_partition_table}
		# TODO Add note about how to save partition table, as with sgdisk.
	fi

	if [ "TRUE" = "${cfg_write_partition_using_sgdisk}" ] ; then
		# There is a complaint that one or more CRCs do not match. Then
		# it is informed that backup partition table will be loaded.
		# The loading succeeds, but sgdisk still seems to exit with
		# error. Thus, do not care about the command indicating an
		# error.
		sgdisk -l=${gentoo_config}/${gpt_partition_backup_file} ${main_block_device} \
			|| true
		# NOTE Save partition table to file by using:
		# `sgdisk -b=sgdisk-sda.bin /dev/sda`
	fi

	mkswap ${swap_partition_dev}
	swapon ${swap_partition_dev}

	if [ "TRUE" = "${cfg_should_setup_lvm}" ] ; then
		pvcreate ${lvm_partition_dev}
		vgcreate ${volgroup_name} ${lvm_partition_dev}

		lvcreate --yes --type linear -L ${root_size} -n ${lv_name_root} ${volgroup_name}
		if [ "TRUE" = "${cfg_setup_home_partition}" ] ; then
			lvcreate --yes --type linear -L ${home_size} -n ${lv_name_home} ${volgroup_name}
		fi
	fi

	mkfs.ext2 -F -F ${boot_partition_dev}
	mkfs.ext4 -F -F ${root_partition_dev}
	if [ "TRUE" = "${cfg_setup_home_partition}" ] ; then
		mkfs.ext4 -F -F ${home_partition_dev}
	fi
}

function setup_stage_tarball() {
	print_header "INSTALLING STAGE TARBALL"
	pushd ${mountpoint_root}

	wget ${frozen_stage3_release_dir}/${stage3_tar}
	wget ${frozen_stage3_release_dir}/${stage3_tar}.DIGESTS.asc # Contains info of .DIGESTS
	if [ "TRUE" != "${DISABLED}" ] ; then
		openssl dgst -r -sha512 ${stage3_tarball_filename} # TODO exit with error message if does not match
	fi

	# From Gentoo wiki:
	# To be absolutely certain that everything is valid, verify the
	# fingerprint shown with the fingerprint on the Gentoo signatures page.
	# Gentoo signatures page: https://www.gentoo.org/downloads/signatures/
	readonly gpg_match="Good signature from \"Gentoo Linux Release Engineering"
	gpg --verify ${stage3_tar}.DIGESTS.asc 2>&1 | grep "${gpg_match}"

	readonly signed_sum="$(grep -A1 SHA512 ${stage3_tar}.DIGESTS.asc | head -2 | grep -v SHA512)"
	readonly calculated_sum="$(sha512sum ${stage3_tar})"
	if [ "${signed_sum}" != "${calculated_sum}" ] ; then
		error_exit "Stage 3 tar sums do not match."
	fi

	tar xpvf ${stage3_tar} --xattrs-include='*.*' --numeric-owner
	popd
}

function setup_portage_configuration() {
	print_header "SETTING UP PORTAGE CONFIGURATION"

	cp ${make_conf} ${mountpoint_root}/etc/portage/make.conf
	mkdir --parents ${mountpoint_root}/etc/portage/repos.conf
	cp \
		${mountpoint_root}/usr/share/portage/config/repos.conf \
		${mountpoint_root}/etc/portage/repos.conf/gentoo.conf
	cp --dereference /etc/resolv.conf ${mountpoint_root}/etc/
}

function setup_portage() {
	emerge-webrsync

	eselect profile set default/linux/amd64/17.1

	emerge sys-auth/elogind --autounmask-write \
		|| true
	etc-update --automode -3 -q # Merge required USE flag changes

	emerge --verbose --update --deep --newuse @world

	# TODO Check if necessary to update make.conf. Was it changed during
	# portage setup?

	# TODO configure ACCEPT_LICENSE
	# to make.conf:
	# ACCEPT_LICENSE="-* @FREE"
	# Per package overrides are also possible. For example can change:
	# /etc/portage/package.license/kernel
}

function setup_timezone() {
	cp ${gentoo_config}/timezone /etc/timezone
	emerge --config sys-libs/timezone-data
}

function setup_locale() {
	cp ${gentoo_config}/locale.gen /etc/locale.gen
	locale-gen
	eselect locale set en_US
	env-update
	source /etc/profile
}

function setup_kernel() {
	emerge sys-kernel/gentoo-sources
	cp ${gentoo_config}/.config ${kernel_sources_dir}

	pushd ${kernel_sources_dir}
	make olddefconfig
	make
	make modules_install
	make install
	popd

	emerge --autounmask-write sys-kernel/linux-firmware \
		|| true
	# TODO check that configuration updates are actually license updates.
	etc-update --automode -3 -q # Merge license changes
	emerge sys-kernel/linux-firmware
}

function setup_lvm() {
	# TODO
	# LVM initramfs support
	# 	* use ldd to verify that binary is static
	# 	* store /usr/src/initramfs/init configuration to ${gentoo_config}
	#		* see: https://wiki.gentoo.org/wiki/Custom_Initramfs#LVM

	print_header "SETUP_LVM"

	# TODO install sys-fs/lvm2 with "static" USE flag
	USE="static static-libs" emerge sys-fs/lvm2

	# First emerge is expected to fail. License changes were required
	# before emerging.
	emerge --autounmask-write sys-kernel/genkernel \
		|| true
	# TODO check that configuration updates are actually license updates.
	etc-update --automode -3 -q # Merge license changes
	emerge sys-kernel/genkernel

	# TODO configuration

	# TODO is --install required?
	# genkernel --lvm initramfs
	genkernel --lvm --install initramfs

	rc-update add lvm boot

	# TODO LVM to kernel commandline. Do this in bootloader setup?
	#
	# /etc/default/grub
	# GRUB_CMDLINE_LINUX="dolvm"
}

function setup_new_system() {
	print_header "SETUP_NEW_SYSTEM"

	# TODO
	# * user account
	# * OpenRC (/etc/rc.conf)
	# * emerge tools (remember that this is the host system)
	# 	* system logger (app-admin/sysklogd)
	#		* logrotate
	# 	* cron
	# 	* dhcp client

	echo "" > ${gentoo_config}/fstab
	echo "UUID=${boot_partition_uuid}	/boot	ext2	defaults,noatime	0 2" >> ${gentoo_config}/fstab
	echo "UUID=${swap_partition_uuid}	none	swap				0 0" >> ${gentoo_config}/fstab
	echo "UUID=${root_volume_uuid}	/	ext4	noatime			0 1" >> ${gentoo_config}/fstab
	echo "UUID=${home_volume_uuid}	/home	ext2	defaults,noatime	0 1" >> ${gentoo_config}/fstab
	cat ${gentoo_config}/fstab >> /etc/fstab

	echo "hostname=\"${new_hostname}\"" >> /etc/conf.d/hostname
	# TODO if no domain name configured, delete string: .\0 from /etc/issue

	emerge --noreplace net-misc/netifrc

	# TODO change interface name, if incorrect
	echo "config_${inet_if}=\"dhcp\"" >> /etc/conf.d/net
	pushd /etc/init.d
	ln -s net.lo net.${inet_if}
	popd
	rc-update add net.${inet_if} default
	# If interface name is changed, need to perform multiple steps.
	# See: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Automatically_start_networking_at_boot

	echo "127.0.0.1	${my_hostname}	${my_hostname}	localhost" >> /etc/hosts

	print_header "SETTING ROOT PASSWORD"
	cached_root_password="$(cat ${chroot_root_password_file_in_ram})"
	echo -e "${cached_root_password}\n${cached_root_password}" | passwd

	# TODO modify and copy to config dir:
	# /etc/rc.conf
	# /etc/conf.d/keymaps
	# /etc/conf.d/hwclock

	emerge app-admin/sysklogd
	rc-update add sysklogd default
	# TODO configure logrotate

	if [ "TRUE" != "${DISABLED}" ] ; then
		emerge sys-apps/cronie
		rc-update add cronie default
	fi

	emerge sys-fs/e2fsprogs
	emerge net-misc/dhcpcd
}

function setup_bootloader() {
	if [ "TRUE" = "${cfg_set_efi64_grub_platform}" ] ; then
		echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	fi

	# TODO select whether to install for BIOS or UEFI

	emerge sys-boot/grub:2

	if [ "TRUE" = "${cfg_install_grub_to_disk}" ] ; then
		grub-install ${main_block_device}
	fi

	grub-mkconfig -o /boot/grub/grub.cfg
}

function setup_packages() {
	emerge --autounmask-write x11-base/xorg-server \
		|| true
	# TODO check that configuration updates are actually license updates.
	etc-update --automode -3 -q # Merge USE flag and license changes
	emerge x11-base/xorg-server
	emerge x11-terms/st \
		x11-misc/dmenu \
		x11-wm/dwm \
		app-editors/vim \
		dev-vcs/git \
		app-admin/sudo \
		app-misc/tmux
}

function setup_accounts() {
	local -r username="testuser"
	groupadd wheel
	useradd -m -G wheel ${username}
}

function setup_remote_access() {
	# TODO enable when have implemented taking stored sshd config into use
	# rc-update add sshd default
	echo "setup_remote_access: Not yet implemented"
}

function install_pre_chroot() {
	print_header "INSTALL_PRE-CHROOT"

	if [ "TRUE" = "${cfg_confirm_config}" ] ; then
		dump_config_and_wait_for_enter
	fi

	store_root_password_to_ram
	import_gentoo_gpg_key
	test "$(should_setup_partitions)" && setup_partitions
	maybe_mount_partitions
	store_root_password_to_file_in_ram
	setup_date_and_time
	setup_stage_tarball
	setup_portage_configuration
}

function install_chroot() {
	print_header "INSTALL_CHROOT"

	maybe_mount_partitions
	maybe_mount_pseudofilesystems

	mkdir -p ${mountpoint_root}/${script_root}/
	cp -r ${script_root}/* ${mountpoint_root}/${script_root}/
	chroot ${mountpoint_root} /bin/bash -c \
		"${script_root}/install_gentoo.sh ${opt_post_chroot}"
}

function install_post_chroot() {
	print_header "INSTALL_POST-CHROOT"

	source /etc/profile

	# TODO use an array to select setup functions to call
	test "$(should_setup_portage)" && setup_portage
	test "$(should_setup_timezone)" && setup_timezone
	test "$(should_setup_locale)" && setup_locale
	test "$(should_setup_kernel)" && setup_kernel
	test "$(should_setup_lvm)" && setup_lvm
	test "$(should_setup_new_system)" && setup_new_system
	test "$(should_setup_bootloader)" && setup_bootloader
	test "$(should_setup_packages)" && setup_packages
	setup_accounts
	setup_remote_access

	if [ "TRUE" = "${cfg_shutdown_when_done}" ] ; then
		shutdown -h now
	fi
}

function main() {
	process_args "$@"

	if [ "TRUE" = "${is_pre_chroot_install}" ] ; then
		install_pre_chroot
	fi

	read_uuids

	if [ "TRUE" = "${call_post_chroot_install}" ] ; then
		install_chroot
	fi

	if [ "TRUE" = "${is_post_chroot_install}" ] ; then
		install_post_chroot
	fi
}

main "$@"
