#!/bin/bash

# Based on: https://aoe2.arkanosis.net/linux/

# Checking for Vulkan support:
# https://docs.vulkan.org/guide/latest/checking_for_support.html#_linux

# Debian cabextract package:
# https://packages.debian.org/trixie/cabextract

set -e

readonly temporary_directory="$(mktemp -d)"
readonly url_vc_redist='https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe'
readonly dir_of_ucrtbase="${HOME}/.steam/steam/steamapps/compatdata/813780/pfx/drive_c/windows/system32"
readonly arg_manual_setup_done='--manual-setup-done'

error_exit() {
	echo "${1}"
	exit 1
}

main() {
	echo "================================="
	echo "Start of manual part of the setup"
	echo "================================="
	echo ""
	echo "1. Navigate to: Steam -> Settings -> Compatibility"
	echo "2. Select at least Proton 8.0-4"
	echo ""
	echo "If lacking Vulkan support, try using OpenGL via WineD3D."
	echo "Set \`PROTON_USE_WINED3D=1 %command%\` in launch options to use"
	echo "WineD3D."
	echo ""
	echo "Install the game via Steam."
	echo ""
	echo "Optionally set \`SKIPINTRO\` in launch options."
	echo ""
	echo "Start the game once."
	echo ""
	echo "==============================="
	echo "End of manual part of the setup"
	echo "==============================="

	if [ "${1}" != "${arg_manual_setup_done}" ] ; then
		echo ""
		echo "To run the automated part of the setup, please run the"
		echo "script with '${arg_manual_setup_done}' as the first"
		echo "argument. Like so: ${0} ${arg_manual_setup_done}"
		echo ""
		exit
	fi

	if [ ! -d "${temporary_directory}" ] ; then
		error_exit "Missing temporary directory"
	fi

	if ! which cabextract &> /dev/null ; then
		error_exit "Missing cabextract"
	fi

	if [ "2" != "$(ls -a -1 "${temporary_directory}" | wc --lines)" ] ; then
		error_exit "Created temporary directory (${temporary_directory}) is not empty"
	fi

	pushd "${temporary_directory}"

	wget "${url_vc_redist}"

	echo "Extracting vc_redist.x64.exe"
	cabextract vc_redist.x64.exe

	cabextract a10

	echo "Deploying ucrtbase.dll"
	chmod u+w "${dir_of_ucrtbase}"/ucrtbase.dll
	yes | cp --verbose ./ucrtbase.dll "${dir_of_ucrtbase}"

	popd # "$(mktemp -d)"

	rm --verbose -rf "${temporary_directory}"

	echo "Done"
}

main "${@}"
