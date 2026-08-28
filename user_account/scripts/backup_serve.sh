#!/bin/bash

set -e

main() {
	local -r official_tar='official.tar'
	local -r database_kdbx='Database.kdbx'
	local -r directory_share_http="${HOME}/my/share_http"

	local -r transfer_port=$(keepassxc-cli \
		show --show-protected \
		${HOME}/my/data/for_programs/keepass/Database.kdbx \
		"for_automation/backups/transfer_port" \
		| grep "Password:" \
		| tr -d ' ' \
		| cut -d ':' -f 2)

	pushd "${directory_share_http}"

	tar --directory=${HOME}/my -c -v -f ${directory_share_http}/${official_tar} ./official/
	cp --verbose ${HOME}/my/data/for_programs/keepass/${database_kdbx} ./

	ip -4 -brief address show
	python3 -m http.server ${transfer_port}
	rm --verbose ./${database_kdbx}
	rm --verbose ./${official_tar}

	popd # "${directory_share_http}"
}

main "${@}"
