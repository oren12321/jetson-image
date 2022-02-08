#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: clone Jetson target to image file.
#
#/ Usage: ./clone_target.sh <clone_name>.img [--update-bootloader]
#/


#{{{ Bash settings
set -eEuo pipefail
trap clone_target_error ERR
#}}}

#{{{ Globals
script_name=$(basename "${0}")
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)
#}}}

#{{{ Imports
source ${script_dir}/log.sh
source ${script_dir}/utils/setup_env.sh
#}}}

#{{{ Helper functions

clone_target_error() {
    lerror "someting went wrong - clone target failed"
}

#}}}


##########
linfo "cloning target ${ART_DIR}/$1"

pushd ${ICACHE_DIR}/Linux_for_Tegra

./flash.sh -r -k APP -G ${ART_DIR}/$1 ${JETSON_BOARD} ${JETSON_STORAGE}

if [ "$2" = "--update-bootloader" ]; then
    linfo "updating system.img with ${ART_DIR}/$1"
    cp ${ART_DIR}/$1 bootloader/system.img
fi

popd

