#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: make initial rootfs for Jetson.
#
#/ Usage: ./make_rootfs.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap make_rootfs_error ERR
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

make_rootfs_error() {
    lerror "someting went wrong - make rootfs failed"
}

#}}}


##########
linfo "bootstrapping base ${RELEASE} rootfs for ${ARCH}"

# Remove ROOTFS_CACHE_DIR content from previous runs
if [ "$(ls -A ${ROOTFS_CACHE_DIR})" ]; then
    lwarning "removing previous content from ${ROOTFS_CACHE_DIR}"
    rm -rf ${ROOTFS_CACHE_DIR}/*
fi

# create a zip file for laster use
# delete the zip file to get new version of packages
# however, app packages will be updated later
if [ ! -f ${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz ]
then
    linfo "downloading packages to ${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz"
    debootstrap \
        --verbose \
        --foreign \
        --make-tarball=${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz \
        --arch=${ARCH} \
        ${RELEASE} \
        ${ROOTFS_CACHE_DIR} \
        ${REPO}
fi

linfo "installing packages from ${ARCH}-${RELEASE}.tgz"
debootstrap \
    --verbose \
    --foreign \
    --unpack-tarball=$(realpath ${ICACHE_DIR}/${ARCH}-${RELEASE}.tgz) \
    --arch=${ARCH} \
    ${RELEASE} \
    ${ROOTFS_CACHE_DIR} \
    ${REPO}

##########
linfo "installing qemu virtual machine to rootfs"

# qemu-aarch64-static will be called by chroot
install -Dm755 $(which qemu-aarch64-static) ${ROOTFS_CACHE_DIR}/usr/bin/qemu-aarch64-static

# ubuntu-keyring package can be installed, but this way is a bit faster ?
install -Dm644 /usr/share/keyrings/ubuntu-archive-keyring.gpg ${ROOTFS_CACHE_DIR}/usr/share/keyrings/ubuntu-archive-keyring.gpg

##########
linfo "running bootsrapping second stage"

chroot ${ROOTFS_CACHE_DIR} /debootstrap/debootstrap --second-stage

