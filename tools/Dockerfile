FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

# image creation section

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        qemu-user-static \
        debootstrap \
        binfmt-support \
        libxml2-utils \
        wget \
 && rm -rf /var/lib/apt/lists/*

# kernel customization section

RUN apt-get update && apt-get install -y --no-install-recommends \
        gdisk \
        parted \
        wget \
        build-essential \
        bc \
        xxd \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/
ARG LINARO_ARCHIVE=gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
ARG LINARO_ARCHIVE_URL=http://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
RUN wget ${LINARO_ARCHIVE_URL} \
 && mkdir /opt/l4t-gcc \
 && tar -xvf ${LINARO_ARCHIVE} -C /opt/l4t-gcc --strip-components 1 \
 && rm -rf /tmp/*
ENV CROSS_COMPILE=/opt/l4t-gcc/bin/aarch64-linux-gnu-

# target flashing

RUN apt-get update && apt-get install -y --no-install-recommends --allow-downgrades \
        python \
        python3 \
        cpio \
        ssh-import-id \
        binutils \
        sudo \
 && rm -rf /var/lib/apt/lists/*

# work tree setup

ENV USER=root

ARG WORK_DIR=/workdir
ENV WORK_DIR=${WORK_DIR}
ENV ROOTFS_CACHE_DIR=${WORK_DIR}/rootfs
ENV ICACHE_DIR=${WORK_DIR}/cache/image
ENV KCACHE_DIR=${WORK_DIR}/cache/kernel
ENV ART_DIR=${WORK_DIR}/artifacts

WORKDIR /tools
COPY . /tools/

CMD ["find", ".", "base-image/others", "-maxdepth", "1", "-type", "f", "-name", "*.sh"]

