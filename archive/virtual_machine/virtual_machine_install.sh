#!/bin/bash

# https://wiki.archlinux.org/index.php/QEMU#Pass-through_host_USB_device

# man virt-install
# --controller usb,model=ich9-ehci1,address=0:0:4.0,index=0
# Adds a ICH9 EHCI1 USB controller on PCI address 0:0:4.0

#	--hostdev 002.003 \
#	--hostdev 002.004 \
#	--hostdev 001.010 \
#	--hostdev 001.011 \

virt-install \
	--name=gentoo_machine \
	--ram=12288 \
	--cpu=host \
	--virt-type=kvm \
	--vcpus=4 \
	--graphics=spice \
	--disk /dev/vg01/gentoo_guest,bus=virtio \
	--cdrom $HOME/my/images/install-amd64-minimal-20190904T214502Z.iso
