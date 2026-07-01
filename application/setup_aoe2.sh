#!/bin/bash

# Based on: https://aoe2.arkanosis.net/linux/

# Checking for Vulkan support:
# https://docs.vulkan.org/guide/latest/checking_for_support.html#_linux

# Debian cabextract package:
# https://packages.debian.org/trixie/cabextract

set -e

temporary_directory="$(mktemp -d)"

error_exit() {
	echo "${1}"
	exit 1
}

main() {
	echo "1. Navigate to: Steam -> Settings -> Compatibility"
	echo "2. Select at least Proton 8.0-4"
	echo ""
	echo "If lacking Vulkan support, try using OpenGL via WineD3D."
	echo "Set `PROTON_USE_WINED3D=1 %command%` in launch options to use WineD3D."
	echo ""
	echo "Install the game via Steam."
	echo ""
	echo "Optionally set `SKIPINTRO` in launch options."
	echo ""
	echo "Start the game once."
	echo ""

	if [ ! -d ${temporary_directory} ] ; then
		error_exit "Missing temporary directory"
	fi

	if ! which cabextract &> /dev/null ; then
		error_exit "Missing cabextract"
	fi

	pushd "${temporary_directory}"

	wget "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe"

	echo "Extracting vc_redist.x64.exe"
	cabextract vc_redist.x64.exe

	cabextract a10

	echo "Deploying ucrtbase.dll"
	chmod u+w ${HOME}/.steam/steam/steamapps/compatdata/813780/pfx/drive_c/windows/system32/ucrtbase.dll
	yes | cp --verbose ./ucrtbase.dll ~/.steam/steam/steamapps/compatdata/813780/pfx/drive_c/windows/system32

	popd # "$(mktemp -d)"

	rm -rf ${temporary_directory}

	echo "Done"
}

main "${@}"
