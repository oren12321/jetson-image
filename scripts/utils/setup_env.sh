#! /usr/bin/env bash
#
# Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
#/ Usage: SCRIPTNAME [OPTIONS]... [ARGUMENTS]...
#/
#/ 
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/  


#{{{ Bash settings
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail
#}}}
#{{{ Variables
readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

#}}}

main() {
    # check_args "${@}"
    :
    validate_root
    validate_ini
    export_ini
    [ "${REPO}" = "" ] && { REPO=$(find_fastest_mirror); linfo "REPO not set - found fastest mirror ${REPO}"; }
    export REPO
}

#{{{ Helper functions

lerror() {
    printf "\e[1;31m%s\e[0m\n" "${*}" 1>&2
}

linfo() {
    printf "\e[1;32m%s\e[0m\n" "${*}"
}

lwarning() {
    printf "\e[1;33m%s\e[0m\n" "${*}"
}

validate_root() {
    if [ "x$(whoami)" != "xroot" ]; then
        lerror "root privileges required"
        exit 1
    fi
}

validate_ini() {
    if [ ! -f ${script_dir}/../env.ini ]; then
        lerror "env.ini not found"
        exit 1
    fi
}

export_ini() {
    source <(grep -E ".+=" ${script_dir}/../env.ini | sed 's/^/export /')
}

find_fastest_mirror() {
    printf $(${script_dir}/./find_mirrors.sh ${ARCH} ${RELEASE} main speed | sort -k 1 | head -n 1 | awk '{print $2}')
}

#}}}

main "${@}"

# cursor: 33 del

