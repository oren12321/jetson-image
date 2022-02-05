#!/bin/bash

source step0_env.sh && \
./step1_make_rootfs.sh && \
./step2_customize_rootfs.sh && \
./step3_apply_bsp.sh && \
tar -jcvf ${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.tbz2 ${WORK_DIR}/Linux_for_Tegra
