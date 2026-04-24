#!/bin/bash

# This script is designed to be `source`d from a shell where loaded credentials
# are to be used.

export DIGITAL_OCEAN_TOOLBOX_USER=$(keepassxc-cli \
	show \
	${HOME}/my/data/for_programs/keepass/Database.kdbx \
	"Network/digital_ocean/toolbox/host/Regular user" \
	| grep "UserName:" \
	| cut -d " " -f 2)
