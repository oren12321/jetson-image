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

if [ ! -f ${LINARO_ARCHIVE} ]; then
    echo "Download LINARO_ARCHIVE"
    wget ${LINARO_ARCHIVE_URL}
fi

mkdir -p ${WORK_DIR}/l4t-gcc
tar -xvf ${LINARO_ARCHIVE} -C ${WORK_DIR}/l4t-gcc --strip-components 1

export CROSS_COMPILE=${WORK_DIR}/l4t-gcc/bin/aarch64-linux-gnu-

#########
echo "Prepare kernel sources"

if [ ! -f ${DRIVER_SOURCES_ARCHIVE} ]; then
    echo "Download DRIVER_SOURCES_ARCHIVE"
    wget ${DRIVER_SOURCES_ARCHIVE_URL}
fi

mkdir -p ${WORK_DIR}/kernel_src
tar -xvf ${LINARO_ARCHIVE} -C ${WORK_DIR}/l4t-gcc --strip-components 1
tar -xvjf ${DRIVER_SOURCES_ARCHIVE}
pushd Linux_for_Tegra/source/public/
tar -xvjf kernel_src.tbz2 -C ${WORK_DIR}/kernel_src
popd
rm -rf Linux_for_Tegra

##########
echo "Prepare kernel build env"

apt install build-essential bc -y --no-install-recommends

TEGRA_KERNEL_OUT=${WORK_DIR}/kernel_out
mkdir -p ${TEGRA_KERNEL_OUT}

export LOCALVERSION=-tegra

##########
echo "Build kernel"

pushd ${WORK_DIR}/kernel_src/kernel/kernel-4.9
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} tegra_defconfig
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} -j$(nproc)
popd


##########
echo "Install and archive kernel supplements"

if [ ! -d ${WORK_DIR}/Linux_for_Tegra ]; then
    echo "Kernel supplements will not be installed - Linux_for_Tegra directory missing"
    exit 0
fi

echo "Copying Image and .dtb files"
pushd ${WORK_DIR}/kernel_out/arch/${ARCH}/boot
cp -a Image ${WORK_DIR}/Linux_for_Tegra/kernel/
rm -rf ${WORK_DIR}/Linux_for_Tegra/kernel/dtb/*
cp -a dts/* ${WORK_DIR}/Linux_for_Tegra/kernel/dtb/
popd

echo "Installing kernel modules"
pushd ${WORK_DIR}/kernel_src/kernel/kernel-4.9
make ARCH=${ARCH} O=${TEGRA_KERNEL_OUT} modules_install INSTALL_MOD_PATH=${WORK_DIR}/Linux_for_Tegra/rootfs/
popd

echo "Archiving kernel modules and applying binaries"
tar --owner root --group root -cvjf kernel_supplements_${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${WORK_DIR}/Linux_for_Tegra/rootfs/lib/modules

cp -a kernel_supplements_${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${WORK_DIR}/Linux_for_Tegra/kernel/kernel_supplements.tbz2
pushd ${WORK_DIR}/Linux_for_Tegra
./apply_binaries.sh
popd

