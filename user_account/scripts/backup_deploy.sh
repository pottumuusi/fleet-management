#!/bin/bash

set -e

main() {
	local -r server_ip="${1}"
	local -r official_tar="official.tar"
	local -r database_kdbx="Database.kdbx"
	local -r database_bak="Database.bak"

	if [ -z "${server_ip}" ] ; then
		echo "Server IP not provided as first argument. Exiting."
		exit 1
	fi

	local -r transfer_port=$(keepassxc-cli \
		show --show-protected \
		${HOME}/my/data/for_programs/keepass/Database.kdbx \
		"for_automation/backups/transfer_port" \
		| grep "Password:" \
		| tr -d ' ' \
		| cut -d ':' -f 2)

	pushd /tmp

	wget http://${server_ip}:${transfer_port}/${database_kdbx}
	wget http://${server_ip}:${transfer_port}/${official_tar}

	cp --verbose \
		${HOME}/my/data/for_programs/keepass/${database_kdbx} \
		${HOME}/my/data/for_programs/keepass/${database_bak}
	mv --verbose ./${database_kdbx} ${HOME}/my/data/for_programs/keepass/

	rm --verbose --recursive --force ${HOME}/my/official/
	tar --directory=${HOME}/my -x -v -f /tmp/${official_tar}

	rm --verbose ./${official_tar}

	popd # /tmp
}

main "${@}"
