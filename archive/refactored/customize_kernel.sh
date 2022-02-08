#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: nvidia developer resources
#
# Description: customize the kernel, install it in the Jetson OS, and repack.
#
#/ Usage: ./make_rootfs.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap customize_kernel_error ERR
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

customize_kernel_error() {
    lerror "someting went wrong - customize kernel failed"
}

#}}}


##########
linfo "preparing cross-compilation toolchain"

if [ ! -f ${KCACHE_DIR}/${LINARO_ARCHIVE} ]; then
    linfo "downloading ${LINARO_ARCHIVE}"
    wget ${LINARO_ARCHIVE_URL} -P ${KCACHE_DIR}
fi

mkdir -p ${KCACHE_DIR}/l4t-gcc
tar -xvf ${KCACHE_DIR}/${LINARO_ARCHIVE} -C ${KCACHE_DIR}/l4t-gcc --strip-components 1

export CROSS_COMPILE=${KCACHE_DIR}/l4t-gcc/bin/aarch64-linux-gnu-

#########
linfo "preparing kernel sources"

if [ ! -f ${KCACHE_DIR}/${DRIVER_SOURCES_ARCHIVE} ]; then
    linfo "downloading ${DRIVER_SOURCES_ARCHIVE}"
    wget ${DRIVER_SOURCES_ARCHIVE_URL} -P ${KCACHE_DIR}
fi

pushd ${KCACHE_DIR}
mkdir -p kernel_src
tar -xvjf ${DRIVER_SOURCES_ARCHIVE}
popd

pushd ${KCACHE_DIR}/Linux_for_Tegra/source/public/
tar -xvjf kernel_src.tbz2 -C ${KCACHE_DIR}/kernel_src
popd
rm -rf ${KCACHE_DIR}/Linux_for_Tegra

##########
linfo "preparing kernel build env"

apt install build-essential bc -y --no-install-recommends

TEGRA_KERNEL_OUT=${KCACHE_DIR}/kernel_out
mkdir -p ${TEGRA_KERNEL_OUT}

export LOCALVERSION=-tegra

##########
linfo "building kernel"

pushd ${KCACHE_DIR}/kernel_src/kernel/kernel-4.9
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} tegra_defconfig
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} -j$(nproc)
popd


##########
linfo "installing and archive kernel supplements"

if [ ! -d ${ICACHE_DIR}/Linux_for_Tegra ]; then
    lwarning "kernel supplements will not be installed - ${ICACHE_DIR}/Linux_for_Tegra directory missing"
    exit 0
fi

linfo "copying Image and .dtb files"
pushd ${KCACHE_DIR}/kernel_out/arch/${ARCH}/boot
cp -a Image ${ICACHE_DIR}/Linux_for_Tegra/kernel/
rm -rf ${ICACHE_DIR}/Linux_for_Tegra/kernel/dtb/*
cp -a dts/* ${ICACHE_DIR}/Linux_for_Tegra/kernel/dtb/
popd

linfo "installing kernel modules"
pushd ${KCACHE_DIR}/kernel_src/kernel/kernel-4.9
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} modules_install INSTALL_MOD_PATH=${ICACHE_DIR}/Linux_for_Tegra/rootfs/
popd

linfo "archiving kernel modules and reapplying binaries"
tar --owner root --group root -cvjf ${KCACHE_DIR}/kernel_supplements_${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${ICACHE_DIR}/Linux_for_Tegra/rootfs/lib/modules

cp -a ${KCACHE_DIR}/kernel_supplements_${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${ICACHE_DIR}/Linux_for_Tegra/kernel/kernel_supplements.tbz2
pushd ${ICACHE_DIR}/Linux_for_Tegra
./apply_binaries.sh
popd

linfo "repacking image"
rm -rf ${ART_DIR}/${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2
pushd ${ICACHE_DIR}
tar -jcvf ${ART_DIR}/${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 Linux_for_Tegra
popd

