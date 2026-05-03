#!/bin/bash
# test-neofetch.sh
# Run this INSIDE your UbuntuBox to preview the neofetch setup before building.
#
# Steps:
#   1. On Windows: copy ubuntubox-logo.png into %USERPROFILE%\UbuntuBox\
#      (that folder is mounted at /root inside UbuntuBox)
#   2. Open UbuntuBox and run:  bash /root/test-neofetch.sh

set -e
LOGO_SRC="/root/ubuntubox-logo.png"
LOGO_DEST="/etc/ubuntubox/ubuntubox-logo.png"
CONF="$HOME/.config/neofetch/config.conf"

echo ""
echo "  UbuntuBox - Neofetch Preview"
echo "  =============================="
echo ""

# ── 1. Install neofetch + chafa ───────────────────────────────────────────────
echo "[1/4] Checking neofetch and chafa..."
if ! command -v neofetch &>/dev/null || ! command -v chafa &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq neofetch chafa
fi
echo "  OK neofetch $(neofetch --version 2>/dev/null | head -1)"
echo "  OK chafa    $(chafa --version 2>/dev/null | head -1)"

# ── 2. Check image ────────────────────────────────────────────────────────────
echo ""
echo "[2/4] Checking for logo..."
if [ ! -f "$LOGO_SRC" ]; then
    echo "  ERROR: $LOGO_SRC not found."
    echo ""
    echo "  Copy ubuntubox-logo.png into %USERPROFILE%\\UbuntuBox\\ on Windows."
    echo "  That folder is mounted at /root inside UbuntuBox."
    exit 1
fi
mkdir -p /etc/ubuntubox
cp "$LOGO_SRC" "$LOGO_DEST"
echo "  OK $LOGO_DEST ready ($(du -h $LOGO_DEST | cut -f1))"

# ── 3. Write neofetch config ──────────────────────────────────────────────────
echo ""
echo "[3/4] Writing neofetch config..."
mkdir -p "$(dirname $CONF)"

cat > "$CONF" << 'NEOFETCH_CONF'
# UbuntuBox neofetch config
# Image backend: chafa with half-block symbols — sharpest in Windows Terminal
image_backend="chafa"
image_source="/etc/ubuntubox/ubuntubox-logo.png"
image_loop="off"
image_size="280px"
gap=4

# chafa options: half-block mode gives best clarity vs pixel-art noise
# --symbols half uses ▀▄ blocks = twice the vertical resolution of spaces
chafa_ctab_mode="256"

print_info() {
    prin "\e[1;38;5;87mUbuntuBox\e[0m"
    prin "\e[1;38;5;75mDeveloped by Hashim Hilal\e[0m"
    info underline
    info "OS"       distro
    info "Kernel"   kernel
    info "Uptime"   uptime
    info "Packages" packages
    info "Shell"    shell
    info "CPU"      cpu
    info "Memory"   memory
    info cols
}

# Cyan/blue palette to match the crystal image
colors=(6 6 6 6 6 6)
bold="on"
underline_enabled="on"
underline_char="-"
separator=":"
title_fqdn="off"
kernel_shorthand="on"
distro_shorthand="off"
os_arch="off"
uptime_shorthand="on"
memory_percent="on"
memory_unit="mib"
package_managers="on"
shell_path="off"
shell_version="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"
term_font="off"
block_range=(0 15)
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"
NEOFETCH_CONF

echo "  OK Config written to $CONF"

# ── 4. Test different chafa sizes so you can pick the best one ────────────────
echo ""
echo "[4/4] Running neofetch..."
echo ""
echo "  TIP: If the image looks too pixelated, edit $CONF"
echo "       and change image_size to a larger value like '300px' or '400px'."
echo "  TIP: Re-run  neofetch  after any config change."
echo ""
echo "======================================================================="
echo ""

neofetch

echo ""
echo "======================================================================="
echo ""
echo "  Happy with it? On Windows run:  .\\build.ps1"
echo "  The logo and config will be baked into the new ubuntu-box.tar"
echo ""
echo "  To tweak:   nano $CONF && neofetch"
echo ""
