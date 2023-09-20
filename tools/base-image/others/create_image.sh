#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: create Jetson .img file.
#
#/ Usage: ./create_image.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap flash_sd_error ERR
#}}}

#{{{ Globals
script_name=$(basename "${0}")
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)
#}}}

#{{{ Imports
source ${script_dir}/../../utils/log.sh
source ${script_dir}/../setup_env.sh
#}}}

#{{{ Helper functions

flash_sd_error() {
    lerror "someting went wrong - create image failed"
}

#}}}

#########
REQUIRED_UDEV_SIZE="$(free -g | sed -n '2 p' | awk '{print $2}')G"
linfo "remonting udev to ${REQUIRED_UDEV_SIZE}"

mount -o remount,size=${REQUIRED_UDEV_SIZE} /dev

##########
IMAGE=${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.img
linfo "creating image ${IMAGE}"

pushd ${ICACHE_DIR}/Linux_for_Tegra/tools

if [ "${JETSON_BOARD_REV}" = ""  ]; then
    ./jetson-disk-image-creator.sh -o ${ART_DIR}/${IMAGE} -b ${JETSON_IMG_BOARD}
else
    ./jetson-disk-image-creator.sh -o ${ART_DIR}/${IMAGE} -b ${JETSON_IMG_BOARD} -r ${JETSON_BOARD_REV}
fi

popd

