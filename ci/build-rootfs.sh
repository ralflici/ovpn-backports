#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

set -euo pipefail

usage() {
	echo "Usage: $0 <debian-12|debian-13|ubuntu-20.04|ubuntu-22.04|ubuntu-24.04> <rootfs-dir>" >&2
	exit 1
}

if [ "$#" -ne 2 ]; then
	usage
fi

distro="$1"
rootfs="$2"

if [ "${distro}" != "debian-12" ] && [ "${distro}" != "debian-13" ] &&
	[ "${distro}" != "ubuntu-20.04" ] && [ "${distro}" != "ubuntu-22.04" ] &&
	[ "${distro}" != "ubuntu-24.04" ]; then
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

build_debian_12() {
	local debian_keyring include
	local debian_packages=(
		"${packages[@]}"
		linux-headers-amd64
		linux-image-amd64
	)

	include=$(IFS=,; echo "${debian_packages[*]}")

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
}

build_debian_13() {
	local debian_keyring include
	local debian_packages=(
		"${packages[@]}"
		linux-headers-amd64
		linux-image-amd64
	)

	include=$(IFS=,; echo "${debian_packages[*]}")

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
		trixie \
		"${rootfs}" \
		"deb http://deb.debian.org/debian trixie main" \
		"deb http://deb.debian.org/debian trixie-updates main" \
		"deb http://security.debian.org/debian-security trixie-security main"
}

build_ubuntu_2004() {
	build_ubuntu focal python3.9
}

build_ubuntu_2204() {
	build_ubuntu jammy
}

build_ubuntu_2404() {
	build_ubuntu noble
}

build_ubuntu() {
	local codename="$1"
	local extra_python="${2:-}"
	local include ubuntu_keyring
	local ubuntu_packages=(
		"${packages[@]}"
		busybox-static
		linux-headers-generic
		linux-image-generic
		systemd-sysv
		udev
	)

	if [ -n "${extra_python}" ]; then
		ubuntu_packages+=("${extra_python}")
	fi

	include=$(IFS=,; echo "${ubuntu_packages[*]}")

	ubuntu_keyring="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
	if [ ! -r "${ubuntu_keyring}" ]; then
		echo "Missing Ubuntu archive keyring: ${ubuntu_keyring}" >&2
		echo "Install ubuntu-keyring on the host." >&2
		exit 1
	fi

	mmdebstrap \
		--variant=minbase \
		--keyring="${ubuntu_keyring}" \
		--include="${include}" \
		"${codename}" \
		"${rootfs}" \
		"deb http://archive.ubuntu.com/ubuntu ${codename} main universe" \
		"deb http://archive.ubuntu.com/ubuntu ${codename}-updates main universe" \
		"deb http://security.ubuntu.com/ubuntu ${codename}-security main universe"
}

case "${distro}" in
debian-12)
	build_debian_12
	;;
debian-13)
	build_debian_13
	;;
ubuntu-20.04)
	build_ubuntu_2004
	;;
ubuntu-22.04)
	build_ubuntu_2204
	;;
ubuntu-24.04)
	build_ubuntu_2404
	;;
esac

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
