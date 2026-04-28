#!/bin/bash

set -e

cd $(dirname $0)

readonly PHASE_INSTALL_ANSIBLE="true"

main() {
    source ./util.sh || error_exit "Failed to load util functions."
    source ./config.sh || error_exit "Failed to load config."

    local -r distribution_name="$(get_distribution_name)"

    # Operating system that provides the runtime for provisioning.
    local hosting_operating_system=''

    echo "Provisioning $(hostname)"

    assert_variable "VENV_DIRECTORY"

    if [ "true" == "${PHASE_INSTALL_ANSIBLE}" ] ; then
        echo "Installing Ansible"
        ./install_ansible.sh || error_exit "Failed to install Ansible"
    fi

    if [ "${DISTRIBUTION_NAME_DEBIAN}" == "${distribution_name}" ] ; then
        hosting_operating_system=${OPERATING_SYSTEM_DEBIAN}
    else
        error_exit "Unsupported operating system: ${distribution_name}"
    fi

    source ${VENV_DIRECTORY}/bin/activate \
        || error_exit "Failed to activate Python virtual environment."

    ansible-playbook                                                        \
        ./playbooks/provision_desktop_host.yml                              \
        --connection=local                                                  \
        --verbose                                                           \
        --diff                                                              \
        --extra-vars "hosting_operating_system=${hosting_operating_system}" \
        --ask-become-pass

    deactivate \
        || error_exit "Failed to deactivate Python virtual environment."

    # TODO Remove virtual environment where Ansible has been installed.
    # If Ansible is required afterwards, install it to
    # my/tools/ansible/.venv in the playbook.
}

main "${@}"
