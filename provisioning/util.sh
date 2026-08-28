error_exit() {
    echo "${1}"
    exit 1
}

assert_variable() {
    if [ -z "${!1}" ] ; then
        error_exit "[!] Variable ${1} has not been set."
    fi
}

get_distribution_name() {
    grep '^NAME=' /etc/os-release | cut -d = -f 2
}
