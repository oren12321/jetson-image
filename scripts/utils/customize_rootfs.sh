#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
# Based on: vuquangtrong/jetson-custom-image
#
# Description: customize rootfs for Jetson.
#
#/ Usage: ./customize_rootfs.sh
#/


#{{{ Bash settings
set -eEuo pipefail
trap customize_rootfs_error ERR
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
        umount "${ROOTFS_DIR}/$mnt" || true
    done
}

customize_rootfs_error() {
    lerror "someting went wrong - customize rootfs failed"
    lerror "trying to umount dependency points"
    umount_dep_points
}

#}}}

##########
linfo "mounting dependency points"

# these mount points are needed for chroot?
# if script halts before unmounting these point, you have to unmount manually
# that is the reason, this script is called in a wrapper, see step2_customize_rootfs.sh
for mnt in sys proc dev dev/pts tmp; do
    mount -o bind "/$mnt" "${ROOTFS_DIR}/$mnt"
done

##########
linfo "setup locale"

chroot ${ROOTFS_DIR} locale-gen en_US
chroot ${ROOTFS_DIR} locale-gen en_US.UTF-8
chroot ${ROOTFS_DIR} update-locale LC_ALL=en_US.UTF-8

##########
linfo "adding nameserver"

cat << EOF > ${ROOTFS_DIR}/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

##########
linfo "adding repos for ${ARCH}"

cat << EOF > ${ROOTFS_DIR}/etc/apt/apt.conf.d/99verify-peer.conf
Acquire::https::Verify-Peer "false";
Acquire::https::Verify-Host "false";
EOF

cat << EOF > ${ROOTFS_DIR}/etc/apt/sources.list
deb [arch=${ARCH}] ${REPO} ${RELEASE} main restricted universe multiverse
deb [arch=${ARCH}] ${REPO} ${RELEASE}-updates main restricted universe multiverse
deb [arch=${ARCH}] ${REPO} ${RELEASE}-security main restricted universe multiverse
EOF

##########
linfo "updating repo source list"

chroot ${ROOTFS_DIR} apt update
chroot ${ROOTFS_DIR} apt upgrade -y

##########
linfo "installing required packages"

# below packages are needed for installing Jetson packages in step #3
chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
    libasound2 \
    libcairo2 \
    libdatrie1 \
    libegl1 \
    libegl1-mesa \
    libevdev2 \
    libfontconfig1 \
    libgles2 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer-plugins-bad1.0-0 \
    libgtk-3-0 \
    libharfbuzz0b \
    libinput10 \
    libjpeg-turbo8 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpangoft2-1.0-0 \
    libpixman-1-0 \
    libpng16-16 \
    libunwind8 \
    libwayland-client0 \
    libwayland-cursor0 \
    libwayland-egl1-mesa \
    libx11-6 \
    libxext6 \
    libxkbcommon0 \
    libxrender1 \
    python \
    python3 \

##########
linfo "installing system packages"

# below packages are needed for system
chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
    wget \
    curl \
    linux-firmware \
    device-tree-compiler \
    network-manager \
    net-tools \
    wireless-tools \
    ssh \

##########
linfo "installing packages for desktop (required: ${JETSON_DESKTOP})"

chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
    xorg

if [ ! -z ${JETSON_DESKTOP} ]; then

    if [ ${JETSON_DESKTOP} == 'openbox' ]; then
        # minimal desktop, only greeter, no taskbar and background
        chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
            lightdm-gtk-greeter \
            lightdm \
            openbox \

    fi

    if [ ${JETSON_DESKTOP} == 'lxde' ]; then
        # lxde with some components
        chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
            lightdm-gtk-greeter \
            lightdm \
            lxde-icon-theme \
            lxde-core \
            lxde-common \
            policykit-1 lxpolkit \
            lxsession-logout \
            gvfs-backends \

    fi

    if [ ${JETSON_DESKTOP} == 'xubuntu' ]; then
        # Xubuntu, better than lxde
        chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
            xubuntu-core \

    fi

    if [ ${JETSON_DESKTOP} == 'ubuntu-mate' ]; then
        # Ubuntu-Mate, similar to Ubuntu
        chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
            ubuntu-mate-core \

    fi

    # below packages are needed for desktop
    chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
        onboard \

fi

##########
linfo "installing extra packages"

# below packages are needed for desktop
chroot ${ROOTFS_DIR} apt install -y --no-install-recommends \
    htop \
    vim \

##########
linfo "cleaning unneeded packages"

chroot ${ROOTFS_DIR} apt autoremove -y
chroot ${ROOTFS_DIR} apt clean

##########
linfo "setup network - dhcp and wifi"

# ubuntu 18.04 us netplan, so it does not use /etc/network/interfaces anymore
cat << EOF > ${ROOTFS_DIR}/etc/netplan/01-netconf.yaml
network:
    version: 2
    renderer: NetworkManager
    ethernets:
        eth0:
            optional: true
            dhcp4: true
    # add wifi setup information here ...
    wifis:
        wlan0:
            access-points:
                "${WIFI_SSID}":
                    password: "${WIFI_PASS}"
            dhcp4: true
            dhcp4-overrides:
                route-metric: 50
EOF

cat << EOF > ${ROOTFS_DIR}/etc/hostname
${JETSON_NAME}
EOF

##########
linfo "umount dependency points"

umount_dep_points
