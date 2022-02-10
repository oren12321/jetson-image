FROM nvcr.io/nvidia/l4t-base:r32.6.1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN echo "deb https://repo.download.nvidia.com/jetson/common r32.6 main" >> /etc/apt/sources.list \
 && echo "deb https://repo.download.nvidia.com/jetson/t186 r32.6 main" >> /etc/apt/sources.list \
 && apt-key adv --fetch-key http://repo.download.nvidia.com/jetson/jetson-ota-public.asc \
 && mkdir -p /opt/nvidia/l4t-packages/ \
 && touch /opt/nvidia/l4t-packages/.nv-l4t-disable-boot-fw-update-in-preinstall \
 && apt-get update \
 && rm -rf /var/lib/apt/lists/*

RUN apt update \
 && apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confnew \
        nvidia-l4t-jetson-multimedia-api \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/bin/bash" ]

