FROM nvcr.io/nvidia/l4t-base:r32.6.1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        gnupg \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG SOC=t186
RUN echo "deb https://repo.download.nvidia.com/jetson/common r32.6 main" >> /etc/apt/sources.list \
 && echo "deb https://repo.download.nvidia.com/jetson/${SOC} r32.6 main" >> /etc/apt/sources.list \
 && apt-key adv --fetch-key http://repo.download.nvidia.com/jetson/jetson-ota-public.asc \
 && mkdir -p /opt/nvidia/l4t-packages/ \
 && touch /opt/nvidia/l4t-packages/.nv-l4t-disable-boot-fw-update-in-preinstall \
 && apt-get update \
 && rm -rf /var/lib/apt/lists/*

RUN apt update \
 && apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confnew \
        nvidia-l4t-jetson-multimedia-api \
 && rm -rf /var/lib/apt/lists/*

ARG USER_UID=1000
ARG USER_GID=1000
WORKDIR /tmp
RUN groupadd -r user -g ${USER_GID} \
 && useradd -u ${USER_UID} -r -g user -m -d /user -s /sbin/nologin -c "" user \
 && adduser user sudo \
 && adduser user root \
 && mkdir -m a=rwx -p /user \
 && echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user \
 && chmod 0440 /etc/sudoers.d/user \
 && sudo usermod -a -G video user \
 && rm -rf /tmp/*

USER user

ENTRYPOINT [ "/bin/bash" ]

