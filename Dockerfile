FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget git vim nano python3 python3-pip \
    net-tools htop jq unzip zip openssh-client \
    build-essential sudo less tree man-db \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash ubuntubox && \
    echo 'ubuntubox ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /root
CMD ["bash"]
