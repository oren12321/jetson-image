#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: apply JETSON BPS packages and create base OS.
#
#/ Usage: ./apply_bps.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap apply_bps_error ERR
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

apply_bps_error() {
    lerror "someting went wrong - apply_bps failed"
}

#}}}

##########

if [ ! -f ${ICACHE_DIR}/${JETSON_BSP} ]; then 
    linfo "downloading ${JETSON_BSP}"
    wget --no-check-certificate ${JETSON_BSP_URL} -P ${ICACHE_DIR}
fi

##########

if [ ! -d ${ICACHE_DIR}/Linux_for_Tegra ]; then
    linfo "extracting ${JETSON_BSP}"
    tar jvxpf ${ICACHE_DIR}/${JETSON_BSP} -C ${ICACHE_DIR}
fi

##########
linfo "copying rootfs"

rm -rf ${ICACHE_DIR}/Linux_for_Tegra/rootfs
cp -rf ${ROOTFS_CACHE_DIR} ${ICACHE_DIR}/Linux_for_Tegra/

# below device files conflict with L4T package install
declare -a remove_files=(
    "dev/random"
    "dev/urandom"
)

for file in "${remove_files[@]}"; do
    uri=${ICACHE_DIR}/Linux_for_Tegra/rootfs/$file
    if [ -e "$uri" ]
    then
        rm -f $uri
    fi
done

#########
linfo "installing extlinux.conf from bootloader to rootfs"
pushd ${ICACHE_DIR}/Linux_for_Tegra
install -Dm644 bootloader/extlinux.conf rootfs/boot/extlinux/extlinux.conf
popd

##########
linfo "setup permission"

# copy from rootfs to L4T does not keep the sudo flag
# so, do set the flag here
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "echo root:$ROOT_PWD | chpasswd"
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chown root:root /usr/bin/sudo"
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chmod u+s /usr/bin/sudo"

# this to fix error when install package
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chown -R man:man /var/cache/man"
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chmod -R 775 /var/cache/man"

##########
linfo "applying jetson binaries"

pushd ${ICACHE_DIR}/Linux_for_Tegra/
./apply_binaries.sh
popd

##########
linfo "adding user: ${JETSON_USR}"

pushd ${ICACHE_DIR}/Linux_for_Tegra/tools
./l4t_create_default_user.sh -u ${JETSON_USR} -p ${JETSON_PWD} -n ${JETSON_NAME} --accept-license
# ./l4t_create_default_user.sh -u ${JETSON_USR} -p ${JETSON_PWD} -n ${JETSON_NAME} --autologin --accept-license
popd

cat << EOF > ${ICACHE_DIR}/Linux_for_Tegra/rootfs/etc/sudoers.d/${JETSON_USR}
${JETSON_USR} ALL=(ALL) NOPASSWD: ALL
EOF

#########
linfo "setting Nvidia repo platform (<SOC>) to ${JETSON_PLAT}"

pushd ${ICACHE_DIR}/Linux_for_Tegra/rootfs/etc/apt/sources.list.d
sed -i "s/<SOC>/$JETSON_PLAT/g" nvidia-l4t-apt-source.list
popd

##########
# if you want to modify BSP, please do that here
# e.g.
# ./custom/patch_bsp.sh

