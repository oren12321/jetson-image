#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
#
# Description: pack the Jetson OS to .tbz2 image file
#
#/ Usage: ./pack_to_tbz2.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap pack_to_tbz2_error ERR
#}}}

#{{{ Globals
script_name=$(basename "${0}")
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)
#}}}

#{{{ Imports
source ${script_dir}/log.sh
#}}}

#{{{ Helper functions

pack_to_tbz2_error() {
    lerror "someting went wrong - pack to tbz2 failed"
}

#}}}

TBZ2_FNAME=${ART_DIR}/${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 

linfo "packing Jetson OS to ${TBZ2_FNAME}"

tar -jcvf ${TBZ2_FNAME} ${ICACHE_DIR}/Linux_for_Tegra

