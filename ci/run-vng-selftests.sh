#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

set -euo pipefail

usage() {
	echo "Usage: $0 <debian-12> <rootfs-dir> <repo-dir>" >&2
	exit 1
}

if [ "$#" -ne 3 ]; then
	usage
fi

distro="$1"
rootfs=$(realpath "$2")
repo=$(realpath "$3")

if [ "${distro}" != "debian-12" ]; then
	echo "Unsupported distro: ${distro}" >&2
	usage
fi

if [ ! -d "${rootfs}" ]; then
	echo "Missing rootfs: ${rootfs}" >&2
	exit 1
fi

if [ ! -x "${repo}/ci/guest-run-selftests.sh" ]; then
	echo "Missing guest test script in ${repo}" >&2
	exit 1
fi

kernel=$(find "${rootfs}/boot" -maxdepth 1 -type f -name 'vmlinuz-*' |
	sort -V | tail -n1)

if [ -z "${kernel}" ]; then
	echo "No kernel image found in ${rootfs}/boot" >&2
	exit 1
fi

kernel_release=${kernel##*/vmlinuz-}
if [ ! -d "${rootfs}/usr/src/linux-headers-${kernel_release}" ]; then
	echo "Missing headers for ${kernel_release}" >&2
	exit 1
fi

echo "Booting ${distro} with ${kernel_release}"

vng \
	--run "${kernel}" \
	--root "${rootfs}" \
	--rw \
	--user root \
	--disable-kvm \
	--disable-monitor \
	--disable-microvm \
	--force-initramfs \
	--network user \
	--cpus "${VNG_CPUS:-2}" \
	--memory "${VNG_MEMORY:-4096M}" \
	--rwdir "/repo=${repo}" \
	-- \
	/repo/ci/guest-run-selftests.sh
