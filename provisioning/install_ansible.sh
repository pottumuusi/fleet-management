#!/bin/bash

set -e

cd $(dirname $0)

debian_install_python_virtual_environment() {
    echo "Installing Python virtual environment package on Debian"

    sudo apt update || error_exit "[!] Failed to apt update"
    sudo apt --yes upgrade || error_exit "[!] Failed to apt upgrade"
    sudo apt --yes autoremove || error_exit "[!] Failed to apt autoremove"

    sudo apt --yes install python3.11-venv \
        || error_exit "[!] Failed to install python3.11-venv"
}

install_python_virtual_environment() {
    if [ "${DISTRIBUTION_NAME_DEBIAN}" == "$(get_distribution_name)" ] ; then
        debian_install_python_virtual_environment
        return
    fi

    error_exit "Unsupported Linux distribution: ${distro_name}"
}

main() {
    source ./util.sh || error_exit "Failed to load util functions."
    source ./config.sh || error_exit "Failed to load config."

    local -r ansible_core_version="2.18.6"

    assert_variable "VENV_DIRECTORY"

    install_python_virtual_environment

    python3 -m venv ${VENV_DIRECTORY} \
        || error_exit "[!] Failed to create Python virtual environment."

    source ${VENV_DIRECTORY}/bin/activate \
        || error_exit "[!] Failed to activate Python virtual environment."

    python3 -m pip -V \
        || error_exit "[!] Failed to print Pip version information."

    python3 -m pip install ansible-core==${ansible_core_version} \
        || error_exit "[!] Failed to install ansible-core."

    ansible --version \
        || error_exit "[!] Failed to print Ansible version."

    deactivate \
        || error_exit "[!] Failed to deactivate Python virtual environment."
}

main "${@}"
