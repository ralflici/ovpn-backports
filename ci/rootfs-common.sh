#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

rootfs_find_kernel_image() {
	local rootfs="$1"
	local kernel=""

	if [ -d "${rootfs}/boot" ]; then
		kernel=$(find "${rootfs}/boot" -maxdepth 1 -type f -name 'vmlinuz-*' |
			sort -V | tail -n1)
	fi

	if [ -n "${kernel}" ]; then
		printf '%s\n' "${kernel}"
		return
	fi

	if [ -d "${rootfs}/lib/modules" ]; then
		kernel=$(find "${rootfs}/lib/modules" -mindepth 2 -maxdepth 2 \
			-type f -name vmlinuz | sort -V | tail -n1)
	fi

	printf '%s\n' "${kernel}"
}

rootfs_kernel_release() {
	local kernel="$1"
	local release

	case "${kernel}" in
	*/vmlinuz-*)
		printf '%s\n' "${kernel##*/vmlinuz-}"
		;;
	*/vmlinuz)
		release=${kernel%/vmlinuz}
		printf '%s\n' "${release##*/}"
		;;
	*)
		return 1
		;;
	esac
}

rootfs_has_kernel_headers() {
	local rootfs="$1"
	local kernel_release="$2"
	local build="${rootfs}/lib/modules/${kernel_release}/build"
	local build_target

	if [ -d "${rootfs}/usr/src/linux-headers-${kernel_release}" ] ||
		[ -d "${rootfs}/usr/src/kernels/${kernel_release}" ] ||
		[ -e "${build}" ]; then
		return 0
	fi

	if [ ! -L "${build}" ]; then
		return 1
	fi

	build_target=$(readlink "${build}")
	case "${build_target}" in
	/*)
		[ -e "${rootfs}${build_target}" ]
		;;
	*)
		[ -e "$(dirname -- "${build}")/${build_target}" ]
		;;
	esac
}
