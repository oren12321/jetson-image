#!/bin/bash

# Create a base custom image for jetson nano
# vuquangtrong@gmail.com
#
# step 3: apply JETSON_BSP

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

if [ ! -f ${ICACHE_DIR}/${JETSON_BSP} ]; then 
    echo "Download JETSON_BSP"
    wget ${JETSON_BSP_URL} -P ${ICACHE_DIR}
fi

##########

if [ ! -d ${ICACHE_DIR}/Linux_for_Tegra ]; then
    echo "Extract JETSON_BSP"
    tar jxpf ${ICACHE_DIR}/${JETSON_BSP} -C ${ICACHE_DIR}
fi

##########
echo "Copy rootfs"

rm -rf ${ICACHE_DIR}/Linux_for_Tegra/rootfs
cp -rf ${ROOTFS_DIR} ${ICACHE_DIR}/Linux_for_Tegra/

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

##########
echo "Set up permission"

# copy from rootfs to L4T does not keep the sudo flag
# so, do set the flag here
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "echo root:$ROOT_PWD | chpasswd"
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chown root:root /usr/bin/sudo"
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chmod u+s /usr/bin/sudo"

# this to fix error when install package
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chown -R man:man /var/cache/man"
chroot ${ICACHE_DIR}/Linux_for_Tegra/rootfs bash -c "chmod -R 775 /var/cache/man"

##########
echo "Apply jetson binaries"

pushd ${ICACHE_DIR}/Linux_for_Tegra/
./apply_binaries.sh
popd

##########
echo "Add user: ${JETSON_USR}"

pushd ${ICACHE_DIR}/Linux_for_Tegra/tools
./l4t_create_default_user.sh -u ${JETSON_USR} -p ${JETSON_PWD} -n ${JETSON_NAME} --accept-license
# ./l4t_create_default_user.sh -u ${JETSON_USR} -p ${JETSON_PWD} -n ${JETSON_NAME} --autologin --accept-license
popd

cat << EOF > ${ICACHE_DIR}/Linux_for_Tegra/rootfs/etc/sudoers.d/${JETSON_USR}
${JETSON_USR} ALL=(ALL) NOPASSWD: ALL
EOF

#########
echo "Set Nvidia repo platform (<SOC>)"

pushd ${ICACHE_DIR}/Linux_for_Tegra/rootfs/etc/apt/sources.list.d
sed -i "s/<SOC>/$JETSON_PLAT/g" nvidia-l4t-apt-source.list
popd

##########
# if you want to modify BSP, please do that here
# e.g.
# ./custom/patch_bsp.sh
