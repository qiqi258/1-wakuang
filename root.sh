#!/bin/sh

############################################################
#                   DEBIAN 12 PROOT VM                     #
############################################################

ROOTFS_DIR="$(pwd)"
export PATH="$PATH:$HOME/.local/usr/bin"
MAX_RETRIES=50
TIMEOUT=10

RESET='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) ARCH_ALT="amd64" ;;
    aarch64|arm64) ARCH_ALT="arm64" ;;
    *) echo -e "${RED}ERROR: Unsupported arch${RESET}"; exit 1 ;;
esac

show_logo() {
clear
echo -e "${CYAN}[*] Debian 12 (GLIBC 2.36) Proot VM${RESET}"
echo ""
}

install_dependencies() {
echo -e "${CYAN}[*] Installing dependencies...${RESET}"
if command -v apt >/dev/null; then
apt update -y
apt install wget curl proot tar xz-utils -y
fi
}

install_debian() {
echo -e "${CYAN}[*] Downloading Debian 12 RootFS...${RESET}"
wget --no-hsts --show-progress -O /tmp/rootfs.tar.gz "https://github.com/termux/proot-distro/releases/download/v4.14.0/debian-bookworm-${ARCH_ALT}-pd-v4.14.0.tar.xz"

echo -e "${GREEN}[*] Extracting...${RESET}"
tar -xpf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
rm -f /tmp/rootfs.tar.gz
}

download_proot() {
mkdir -p "$ROOTFS_DIR/usr/local/bin"
wget --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" "https://proot.gitlab.io/proot/bin/proot"
chmod +x "$ROOTFS_DIR/usr/local/bin/proot"
}

configure_system() {
echo "nameserver 8.8.8.8" > "$ROOTFS_DIR/etc/resolv.conf"
touch "$ROOTFS_DIR/.installed"
}

# ====================== MAIN ======================
show_logo
install_dependencies

if [ ! -f .installed ]; then
    install_debian
    download_proot
    configure_system
fi

echo -e "${GREEN}[*] Starting Debian 12...${RESET}"
echo -e "${YELLOW}[*] 进去后直接跑你的挖矿程序，不会再报GLIBC错误！${RESET}"
echo ""

exec "$ROOTFS_DIR/usr/local/bin/proot" \
--rootfs="$ROOTFS_DIR" \
-0 -w /root \
-b /dev -b /sys -b /proc -b /tmp \
-b /etc/resolv.conf \
--kill-on-exit \
/usr/bin/env -i \
HOME=/root TERM="$TERM" \
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
/bin/bash --login
