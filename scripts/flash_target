#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: flash Jetson image to target.
#
#/ Usage: ./flash_target.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap flash_target_error ERR
#}}}

#{{{ Globals
script_name=$(basename "${0}")
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)
#}}}

#{{{ Imports
source ${script_dir}/utils/log.sh
source ${script_dir}/utils/setup_env.sh
#}}}

#{{{ Helper functions

flash_target_error() {
    lerror "someting went wrong - flash target failed"
}

#}}}


##########
linfo "flashing target"

pushd ${ICACHE_DIR}/Linux_for_Tegra

./flash.sh ${JETSON_BOARD} ${JETSON_STORAGE}

popd

