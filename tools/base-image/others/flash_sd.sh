#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: flash SD card with .img file.
#
#/ Usage: ./flash_sd.sh <block_device>
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
    lerror "someting went wrong - flash SD failed"
}

#}}}

##########
linfo "checking that $1 is a block device"

if [ ! -b $1 ] || [ "$(lsblk | grep -w $(basename $1) | awk '{print $6}')" != "disk" ]; then
	lerror "$1 is not a block device!"
	exit 1
fi

##########
linfo "umount $1 if required"

if [ "$(mount | grep $1)" ]; then
	for mount_point in $(mount | grep $1 | awk '{ print $1}'); do
		umount $mount_point && true
	done
fi

##########
linfo "flashing $1 with ${IMAGE}"
IMAGE=${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.img
if [ ! -f ${ART_DIR}/${IMAGE} ]; then
    lerror "no .img file found"
    exit 1
fi
dd if=${ART_DIR}/${IMAGE} of=$1 bs=4M conv=fsync status=progress

##########
linfo "extending the partition"

partprobe $1
sgdisk -e $1

end_sector=$(sgdisk -p $1 |  grep -i "Total free space is" | awk '{ print $5 }')
start_sector=$(sgdisk -i 1 $1 | grep "First sector" | awk '{print $3}')

linfo "start_sector = ${start_sector}, end_sector = ${end_sector}"

sgdisk -d 1 $1
sgdisk -n 1:${start_sector}:${end_sector} $1
sgdisk -c 1:APP $1

##########
linfo "extending the filesystem"

if [[ $(basename $1) =~ mmc ]]; then
	e2fsck -fp $1"p1"
	resize2fs $1"p1"
fi

if [[ $(basename $1) =~ sd ]]; then
	e2fsck -fp $1"1"
	resize2fs $1"1"
fi

sync

