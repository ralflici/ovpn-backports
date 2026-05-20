#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

set -euo pipefail

script_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)

# shellcheck source=ci/rootfs-common.sh
. "${script_dir}/rootfs-common.sh"

usage() {
	echo "Usage: $0 <debian-12|debian-13|ubuntu-20.04|ubuntu-22.04|ubuntu-24.04|fedora-44> <rootfs-dir> <repo-dir>" >&2
	exit 1
}

if [ "$#" -ne 3 ]; then
	usage
fi

distro="$1"
rootfs=$(realpath "$2")
repo=$(realpath "$3")

if [ "${distro}" != "debian-12" ] && [ "${distro}" != "debian-13" ] &&
	[ "${distro}" != "ubuntu-20.04" ] && [ "${distro}" != "ubuntu-22.04" ] &&
	[ "${distro}" != "ubuntu-24.04" ] && [ "${distro}" != "fedora-44" ]; then
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

kernel=$(rootfs_find_kernel_image "${rootfs}")

if [ -z "${kernel}" ]; then
	echo "No kernel image found in ${rootfs}" >&2
	exit 1
fi

kernel_release=$(rootfs_kernel_release "${kernel}")

if ! rootfs_has_kernel_headers "${rootfs}" "${kernel_release}"; then
	echo "Missing headers for ${kernel_release}" >&2
	exit 1
fi

vng_args=()
if [ -e /dev/kvm ]; then
	echo "Using KVM acceleration"
else
	echo "KVM unavailable, using QEMU emulation"
	vng_args+=(--disable-kvm)
fi
if [ "${VNG_VERBOSE:-1}" = "1" ]; then
	vng_args+=(--verbose)
fi

echo "Booting ${distro} with ${kernel_release}"

vng \
	--run "${kernel}" \
	--root "${rootfs}" \
	--rw \
	--user root \
	"${vng_args[@]}" \
	--disable-microvm \
	--force-initramfs \
	--cpus "${VNG_CPUS:-2}" \
	--memory "${VNG_MEMORY:-4096M}" \
	--rwdir "/repo=${repo}" \
	-- \
	/repo/ci/guest-run-selftests.sh
