#!/bin/bash

# Create a base custom image for jetson nano
# vuquangtrong@gmail.com
#
# step 0: set up environment

export DEBIAN_FRONTEND=noninteractive

##########
echo "Set target release version"

ARCH=arm64
RELEASE=bionic
# REPO=http://mirror.coganng.com/ubuntu-ports
# REPO=http://mirror.misakamikoto.network/ubuntu-ports

# If REPO is empty, http://ports.ubuntu.com/ubuntu-ports will be used
if [ -z "${REPO}"]
then
    REPO=http://ports.ubuntu.com/ubuntu-ports
fi

# Use below script to get the fastest repo
# if [ -z "${REPO}" ]
# then
#     REPO=$(./find_mirrors.sh arm64 bionic main speed | sort -k 1 | head -n 1 | awk '{print $2}')
# fi

echo "Set target platform"

JETSON_BOARD=jetson-tx2-devkit
JETSON_STORAGE=mmcblk0p1
JETSON_BOARD_IMG=jetson-tx2
JETSON_BOARD_REV=300
JETSON_PLAT=t186
JETSON_REL=r32.6
JETSON_BSP=jetson_linux_r32.6.1_aarch64.tbz2
JETSON_BSP_URL=https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/t186/jetson_linux_r32.6.1_aarch64.tbz2

echo "Set kernel platfrom"

LINARO_ARCHIVE=gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
LINARO_ARCHIVE_URL=http://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz

DRIVER_SOURCES_ARCHIVE=public_sources.tbz2
DRIVER_SOURCES_ARCHIVE_URL=https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/sources/t186/public_sources.tbz2

echo "Set target directories"

WORK_DIR="${HOME}/jetson-workspace"

ICACHE_DIR="${WORK_DIR}/icache"
KCACHE_DIR="${WORK_DIR}/kcache"
ROOTFS_DIR="${ICACHE_DIR}/rootfs"
ART_DIR="${WORK_DIR}/artifacts"

echo "Set system users"

ROOT_PWD=root

JETSON_NAME=jetson
JETSON_USR=jetson
JETSON_PWD=jetson

echo "Set desktop manager"

# leave it empty to not install any DE
JETSON_DESKTOP=

# just a minimal desktop
# JETSON_DESKTOP=openbox

# some panels from lxde
# JETSON_DESKTOP=lxde

# look better and lightweight
# JETSON_DESKTOP=xubuntu

# more similar to ubuntu
# JETSON_DESKTOP=ubuntu-mate

echo "Set network settings"

WIFI_SSID=jetson
WIFI_PASS=jetson

##########
echo "Prepare environment"

mkdir -p ${ICACHE_DIR}
mkdir -p ${KCACHE_DIR}
mkdir -p ${ROOTFS_DIR}
mkdir -p ${ART_DIR}

echo "ARCH = ${ARCH}"
echo "RELEASE = ${RELEASE}"
echo "REPO = ${REPO}"

echo "JETSON_PLAT = ${JETSON_PLAT}"
echo "JETSON_REL = ${JETSON_REL}"
echo "JETSON_BSP = ${JETSON_BSP}"
echo "JETSON_BSP_URL = ${JETSON_BSP_URL}"

echo "WORK_DIR = ${WORK_DIR}"

echo "ROOT_PWD =${ROOT_PWD}"
echo "JETSON_NAME = ${JETSON_NAME}"
echo "JETSON_USR = ${JETSON_USR}"
echo "JETSON_PWD = ${JETSON_PWD}"
echo "JETSON_DESKTOP = ${JETSON_DESKTOP}"
