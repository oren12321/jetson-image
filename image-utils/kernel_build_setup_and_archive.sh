#!/bin/bash

# Download the kernel, build it, setup the Tegra OS with it, and archive it

##########
echo "Check root permission"

if [ "x$(whoami)" != "xroot" ]; then
	echo "This script requires root privilege!!!"
	exit 1
fi

##########
echo "Get environment"

source ./step0_env.sh


##########
echo "Set script options"

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

##########
echo "Prepare toolchain"

if [ ! -f ${KCACHE_DIR}/${LINARO_ARCHIVE} ]; then
    echo "Download LINARO_ARCHIVE"
    wget ${LINARO_ARCHIVE_URL} -P ${KCACHE_DIR}
fi

mkdir -p ${KCACHE_DIR}/l4t-gcc
tar -xvf ${KCACHE_DIR}/${LINARO_ARCHIVE} -C ${KCACHE_DIR}/l4t-gcc --strip-components 1

export CROSS_COMPILE=${KCACHE_DIR}/l4t-gcc/bin/aarch64-linux-gnu-

#########
echo "Prepare kernel sources"

if [ ! -f ${KCACHE_DIR}/${DRIVER_SOURCES_ARCHIVE} ]; then
    echo "Download DRIVER_SOURCES_ARCHIVE"
    wget ${DRIVER_SOURCES_ARCHIVE_URL} -P ${KCACHE_DIR}
fi

pushd ${KCACHE_DIR}
mkdir -p kernel_src
tar -xvjf ${DRIVER_SOURCES_ARCHIVE}
popd

pushd ${KCACHE_DIR}/Linux_for_Tegra/source/public/
tar -xvjf kernel_src.tbz2 -C ${KCACHE_DIR}/kernel_src
popd
rm -rf ${KCAHCE_DIR}/Linux_for_Tegra

##########
echo "Prepare kernel build env"

apt install build-essential bc -y --no-install-recommends

TEGRA_KERNEL_OUT=${KCACHE_DIR}/kernel_out
mkdir -p ${TEGRA_KERNEL_OUT}

export LOCALVERSION=-tegra

##########
echo "Build kernel"

pushd ${KCACHE_DIR}/kernel_src/kernel/kernel-4.9
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} tegra_defconfig
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} -j$(nproc)
popd


##########
echo "Install and archive kernel supplements"

if [ ! -d ${ICACHE_DIR}/Linux_for_Tegra ]; then
    echo "Kernel supplements will not be installed - Linux_for_Tegra directory missing"
    exit 0
fi

echo "Copying Image and .dtb files"
pushd ${KCACHE_DIR}/kernel_out/arch/${ARCH}/boot
cp -a Image ${ICACHE_DIR}/Linux_for_Tegra/kernel/
rm -rf ${ICACHE_DIR}/Linux_for_Tegra/kernel/dtb/*
cp -a dts/* ${ICACHE_DIR}/Linux_for_Tegra/kernel/dtb/
popd

echo "Installing kernel modules"
pushd ${KCACHE_DIR}/kernel_src/kernel/kernel-4.9
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} modules_install INSTALL_MOD_PATH=${ICACHE_DIR}/Linux_for_Tegra/rootfs/
popd

echo "Archiving kernel modules and applying binaries"
tar --owner root --group root -cvjf ${KCACHE_DIR}/kernel_supplements_${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${KCACHE_DIR}/Linux_for_Tegra/rootfs/lib/modules

cp -a ${KCACHE_DIR}/kernel_supplements_${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${ICACHE_DIR}/Linux_for_Tegra/kernel/kernel_supplements.tbz2
pushd ${ICACHE_DIR}/Linux_for_Tegra
./apply_binaries.sh
popd

echo "Repacking image"
rm -rf ${ART_DIR}/${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2
tar -jcvf ${ART_DIR}/${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${ICACHE_DIR}/Linux_for_Tegra

