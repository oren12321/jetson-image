#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
#
# Description: install systemd services.
#
#/ Usage: ./install_systemd_services.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap install_daemon_error ERR
trap install_daemon_int SIGINT
#}}}

#{{{ Globals
script_name=$(basename "${0}")
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)
#}}}

#{{{ Imports
source ${script_dir}/../../aux/log.sh
#}}}

#{{{ Helper functions

umount_dep_points() {
    for mnt in tmp dev/pts dev proc sys; do
        umount "${ICACHE_DIR}/Linux_for_Tegra/rootfs/$mnt" || true
    done
}

install_daemon_error() {
    lerror "someting went wrong - install daemon failed"
    lerror "trying to umount dependency points"
    umount_dep_points
}

install_daemon_int() {
    lwarning "install daemon interrupted - trying to umount dependency points"
    umount_dep_points
}

#}}}


##########
linfo "insalling qemu user to rootfs and mounting dependency points"

install -Dm755 $(which qemu-aarch64-static) ${ICACHE_DIR}/Linux_for_Tegra/rootfs/usr/bin/qemu-aarch64-static

for mnt in sys proc dev dev/pts tmp; do
    mount -o bind "/$mnt" "${ICACHE_DIR}/Linux_for_Tegra/rootfs/$mnt"
done

#########
linfo "installing daemon service"

pushd ${ICACHE_DIR}/Linux_for_Tegra/rootfs

services_dir="${script_dir}/../../systemd-services"

mkdir -p home/${JETSON_USR}/services
daemon_files=$(ls ${services_dir}/*.sh)
for f in $daemon_files; do
    cp ${f} home/${JETSON_USR}/services/
done

service_files=$(ls ${services_dir}/*.service)
for f in $service_files; do
    cp ${f} etc/systemd/system/
    service_name=$(basename ${f} .service)
    chroot . systemctl enable ${service_name}
done

##########
linfo "uninstalling qemu user from rootfs and umouting dependency points"

rm -rf ${ICACHE_DIR}/Linux_for_Tegra/rootfs/usr/bin/qemu-aarch64-static
umount_dep_points

##########
linfo "removing temp rootfs files"

pushd ${ICACHE_DIR}/Linux_for_Tegra/rootfs
rm -rf var/lib/apt/lists/*
rm -rf dev/*
rm -rf var/log/*
rm -rf var/tmp/*
rm -rf var/cache/apt/archives/*.deb
rm -rf tmp/*
popd

