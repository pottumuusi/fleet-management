#!/bin/bash

function print_header() {
	echo -e "\n//////////////////// $1 ////////////////////\n"
}

function error_exit() {
	echo -e "$1\nExiting..."
	exit 1
}

function debug_print() {
	echo "[DEBUG] $1"
}

function is_mounted() {
	local -r path=$1

	if [ -n "$(mount | grep ${path})" ] ; then
		echo "TRUE"
		return
	fi

	echo "FALSE"
}

# Modify config.sh to change what to setup.
function should_setup_portage() {
	if [ "TRUE" = "${cfg_should_setup_portage}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_timezone() {
	if [ "TRUE" = "${cfg_should_setup_timezone}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_locale() {
	if [ "TRUE" = "${cfg_should_setup_locale}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_kernel() {
	if [ "TRUE" = "${cfg_should_setup_kernel}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_lvm() {
	if [ "TRUE" = "${cfg_should_setup_lvm}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_new_system() {
	if [ "TRUE" = "${cfg_should_setup_new_system}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_bootloader() {
	if [ "TRUE" = "${cfg_should_setup_bootloader}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_packages() {
	if [ "TRUE" = "${cfg_should_setup_packages}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function should_setup_partitions() {
	if [ "TRUE" = "${cfg_should_setup_partitions}" ] ; then
		echo "TRUE"
		return
	fi

	echo ""
}

function read_uuids() {
	readonly boot_partition_uuid="$(blkid | grep ${boot_partition_dev} | cut -d \" -f 2)"
	readonly swap_partition_uuid="$(blkid | grep ${swap_partition_dev} | cut -d \" -f 2)"
	readonly home_volume_uuid="$(blkid | grep "${volgroup_name}-${lv_name_home}" | cut -d \" -f 2)"
	readonly root_volume_uuid="$(blkid | grep "${volgroup_name}-${lv_name_root}" | cut -d \" -f 2)"
}
