#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: setup environment for Jetson image/kernel utils.
#
#/ Usage: ./setup_env.sh
#/


#{{{ Bash settings
set -euo pipefail
#}}}

#{{{ Globals
readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)
#}}}

#{{{ Imports
source ${script_dir}/log.sh
#}}}

main() {
    # check_args "${@}"
    :
    validate_root
    validate_ini
    export_ini
    [ "${REPO}" = "" ] && { REPO=$(find_fastest_mirror); linfo "REPO not set - found fastest mirror ${REPO}"; }
    export REPO
    create_workspace
}

#{{{ Helper functions

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

create_workspace() {
    ICACHE_DIR=${WORK_DIR}/icache
    KCACHE_DIR=${WORK_DIR}/kcache
    ROOTFS_DIR=${ICACHE_DIR}/rootfs
    ART_DIR=${WORK_DIR}/artifacts

    mkdir -p ${ICACHE_DIR}
    mkdir -p ${KCACHE_DIR}
    mkdir -p ${ROOTFS_DIR}
    mkdir -p ${ART_DIR}

    export ICACHE_DIR
    export KCACHE_DIR
    export ROOTFS_DIR
    export ART_DIR
}

#}}}

main "${@}"

