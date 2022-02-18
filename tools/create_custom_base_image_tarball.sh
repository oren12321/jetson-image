#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
#
# Description: creaet custom Jetson base image tarball.
#
#/ Usage: ./create_custom_base_image_tarball.sh
#/

#{{{ Bash settings
set -eEuo pipefail
#}}}

pushd ./base-image

source ./setup_env.sh

./make_rootfs.sh
./customize_rootfs.sh
./apply_bsp.sh
./optionals/customize_bsp.sh
./optionals/install_systemd_services.sh
./optionals/customize_kernel.sh
./pack_to_tbz2.sh

popd

