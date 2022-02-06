#!/bin/bash

# Create a base custom image for jetson nano
# vuquangtrong@gmail.com
#
# step 1: make rootfs

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
echo "Install tools"

apt install -y --no-install-recommends \
    qemu-user-static \
    debootstrap \
    binfmt-support \
    libxml2-utils

##########
echo "Debootstrap a base"

# Remove ROOTFS_DIR content from previous runs
rm -rf ${ROOTFS_DIR}/*

# create a zip file for laster use
# delete the zip file to get new version of packages
# however, app packages will be updated later
if [ ! -f ${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz ]
then
    echo "Download packages to ${ARCH}-${RELEASE}.tgz"
    debootstrap \
        --verbose \
        --foreign \
        --make-tarball=${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz \
        --arch=${ARCH} \
        ${RELEASE} \
        ${ROOTFS_DIR} \
        ${REPO}
fi

echo "Install packages from ${ARCH}-${RELEASE}.tgz"
debootstrap \
    --verbose \
    --foreign \
    --unpack-tarball=$(realpath ${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz) \
    --arch=${ARCH} \
    ${RELEASE} \
    ${ROOTFS_DIR} \
    ${REPO}

##########
echo "Install virtual machine"

# qemu-aarch64-static will be called by chroot
install -Dm755 $(which qemu-aarch64-static) ${ROOTFS_DIR}/usr/bin/qemu-aarch64-static

# ubuntu-keyring package can be installed, but this way is a bit faster ?
install -Dm644 /usr/share/keyrings/ubuntu-archive-keyring.gpg ${ROOTFS_DIR}/usr/share/keyrings/ubuntu-archive-keyring.gpg

##########
echo "Unpack ${ROOTFS_DIR}"

chroot ${ROOTFS_DIR} /debootstrap/debootstrap --second-stage
