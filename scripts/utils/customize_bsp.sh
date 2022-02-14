#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: apply customizations for JETSON_BSP.
#
#/ Usage: ./customize_bsp.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap customize_bsp_error ERR
trap customize_bsp_int SIGINT
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

umount_dep_points() {
    for mnt in tmp dev/pts dev proc sys; do
        umount "${ICACHE_DIR}/Linux_for_Tegra/rootfs/$mnt" || true
    done
}

customize_bsp_error() {
    lerror "someting went wrong - customize BSP failed"
    lerror "trying to umount dependency points"
    umount_dep_points
}

customize_bsp_int() {
    lwarning "customize BSP interrupted - trying to umount dependency points"
    umount_dep_points
}

#}}}


##########
linfo "insalling qemu user to rootfs and mounting dependency points"

install -Dm755 $(which qemu-aarch64-static) ${ICACHE_DIR}/Linux_for_Tegra/rootfs/usr/bin/qemu-aarch64-static

for mnt in sys proc dev dev/pts tmp; do
    mount -o bind "/$mnt" "${ICACHE_DIR}/Linux_for_Tegra/rootfs/$mnt"
done

##########
linfo "installing nvidia container runtime"

chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs apt update
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs apt install -y --no-install-recommends nvidia-container-runtime

##########
linfo "removing unrequired installations"

chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs apt autoremove -y
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs apt clean

##########
linfo "uninstalling qemu user from rootfs and umouting dependency points"

rm -rf ${ICACHE_DIR}/Linux_for_Tegra/rootfs/usr/bin/qemu-aarch64-static
umount_dep_points

