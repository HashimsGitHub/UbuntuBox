FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Core packages + neofetch + chafa ─────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    bash curl wget git vim nano python3 python3-pip \
    net-tools htop jq unzip zip openssh-client \
    build-essential sudo less tree man-db \
    neofetch chafa \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && which neofetch || (echo "ERROR: neofetch not installed" && exit 1) \
    && which chafa    || (echo "ERROR: chafa not installed"    && exit 1)

# ── Create ubuntubox user ─────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash ubuntubox && \
    echo 'ubuntubox ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# ── Bake in the UbuntuBox logo ────────────────────────────────────────────────
COPY ubuntubox-logo.png /etc/ubuntubox/ubuntubox-logo.png

# ── Neofetch config ───────────────────────────────────────────────────────────
RUN mkdir -p /root/.config/neofetch
COPY neofetch.conf /root/.config/neofetch/config.conf

# ── Colour theme: full .bashrc (prompt + ls + grep + man colours) ─────────────
COPY bashrc /root/.bashrc

# ── Apply same theme to ubuntubox user ───────────────────────────────────────
RUN cp /root/.bashrc /home/ubuntubox/.bashrc && \
    chown ubuntubox:ubuntubox /home/ubuntubox/.bashrc

WORKDIR /root
CMD ["bash"]
