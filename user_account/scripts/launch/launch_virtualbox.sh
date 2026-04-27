#!/bin/bash

set -e

main() {
	read -s -p "Please provide password for password database: " db_pw

	local -r target_disk_uuid=$(echo ${db_pw} | keepassxc-cli \
		show \
		--show-protected \
		${HOME}/my/data/for_programs/keepass/Database.kdbx \
		Network/home/cheetah/virtual_machine_disk_uuid \
		| grep Password: \
		| cut -d ' ' -f 2)
	local -r cpu_specific_kvm_module=$(echo ${db_pw} | keepassxc-cli \
		show \
		--show-protected \
		${HOME}/my/data/for_programs/keepass/Database.kdbx \
		Network/home/cheetah/processor_specific_kvm_module \
		| grep Password: \
		| cut -d ' ' -f 2)

	if [ -z "${target_disk_uuid}" ] ; then
		echo "Missing value for target_disk_uuid"
		exit 1
	fi

	if [ -z "${cpu_specific_kvm_module}" ] ; then
		echo "Missing value for cpu_specific_kvm_module"
		exit 1
	fi

	echo "Checking virtual machine disk precense"
	if $(sudo /sbin/blkid | grep -q "${target_disk_uuid}") ; then
		echo "Mounting disk that is used for storing virtual machines"
		sudo mount UUID="${target_disk_uuid}" /mnt/temp
	else
		echo "Disks to mount not found"
	fi

	# VirtualBox fails to start virtual machines if the kvm kernel modules
	# are running. Trying to start results in error: "AMD-V is being used
	# by another hypervisor (VERR_SVM_IN_USE).".
	echo "Stopping KVM kernel modules"
	sudo modprobe -r "${cpu_specific_kvm_module}"
	sudo modprobe -r kvm

	virtualbox
}

main "${@}"
