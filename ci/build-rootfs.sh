#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

set -euo pipefail

usage() {
	echo "Usage: $0 <debian-12> <rootfs-dir>" >&2
	exit 1
}

if [ "$#" -ne 2 ]; then
	usage
fi

distro="$1"
rootfs="$2"

if [ "${distro}" != "debian-12" ]; then
	echo "Unsupported distro: ${distro}" >&2
	usage
fi

if [ -e "${rootfs}" ]; then
	echo "Rootfs path already exists: ${rootfs}" >&2
	exit 1
fi

mkdir -p "$(dirname "${rootfs}")"

packages=(
	bc
	binutils
	bison
	build-essential
	ca-certificates
	diffutils
	flex
	git
	iperf3
	iproute2
	iputils-ping
	jq
	kmod
	libelf-dev
	libmbedtls-dev
	libnl-3-dev
	libnl-genl-3-dev
	libssl-dev
	linux-headers-amd64
	linux-image-amd64
	make
	nftables
	pkg-config
	procps
	psmisc
	python3
	python3-jsonschema
	python3-yaml
	rsync
	tcpdump
)

include=$(IFS=,; echo "${packages[*]}")

debian_keyring="/usr/share/keyrings/debian-archive-keyring.gpg"
if [ ! -r "${debian_keyring}" ]; then
	echo "Missing Debian archive keyring: ${debian_keyring}" >&2
	echo "Install debian-archive-keyring on the host." >&2
	exit 1
fi

mmdebstrap \
	--variant=minbase \
	--keyring="${debian_keyring}" \
	--include="${include}" \
	bookworm \
	"${rootfs}" \
	"deb http://deb.debian.org/debian bookworm main" \
	"deb http://deb.debian.org/debian bookworm-updates main" \
	"deb http://security.debian.org/debian-security bookworm-security main"

if ! compgen -G "${rootfs}/boot/vmlinuz-*" >/dev/null; then
	echo "No kernel image found in ${rootfs}/boot" >&2
	exit 1
fi

kernel=$(find "${rootfs}/boot" -maxdepth 1 -type f -name 'vmlinuz-*' |
	sort -V | tail -n1)
kernel_release=${kernel##*/vmlinuz-}

if [ ! -d "${rootfs}/usr/src/linux-headers-${kernel_release}" ]; then
	echo "Missing headers for ${kernel_release}" >&2
	exit 1
fi

echo "Built ${distro} rootfs at ${rootfs}"
echo "Kernel: ${kernel_release}"
