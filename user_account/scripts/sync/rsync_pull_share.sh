#!/bin/bash

readonly OPTIONS_LIVEFIRE=" \
--update \
--recursive \
--times \
--atimes \
--progress \
--delete"

readonly OPTIONS_DRYRUN="${OPTIONS_LIVEFIRE} --dry-run"

main() {
    local -r share_source="/home/${DIGITAL_OCEAN_TOOLBOX_USER}/share/"
    local -r share_destination="${HOME}/my/share/"

    local rsync_options=''

    if [ -z "${DIGITAL_OCEAN_TOOLBOX_USER}" ] ; then
	    echo "Please set a value for variable: DIGITAL_OCEAN_TOOLBOX_USER"
	    exit 1
    fi

    if [ "--livefire" == "${1}" ] ; then
        rsync_options="${OPTIONS_LIVEFIRE}"
    else
        rsync_options="${OPTIONS_DRYRUN}"
    fi

    rsync \
        ${rsync_options} \
        ${DIGITAL_OCEAN_TOOLBOX_USER}@toolbox.justworks.today:${share_source} \
        ${share_destination}
}

main ${@}
