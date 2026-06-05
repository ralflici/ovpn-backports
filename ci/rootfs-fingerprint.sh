#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

set -euo pipefail

script_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)

# shellcheck source=ci/rootfs-common.sh
. "${script_dir}/rootfs-common.sh"

usage() {
	echo "Usage: $0 <target> <rootfs-dir> <repo-sha>" >&2
	exit 1
}

if [ "$#" -ne 3 ]; then
	usage
fi

target="$1"
rootfs="$2"
repo_sha="$3"

kernel=$(rootfs_find_kernel_image "${rootfs}")
if [ -z "${kernel}" ]; then
	echo "No kernel image found in ${rootfs}" >&2
	exit 1
fi

kernel_release=$(rootfs_kernel_release "${kernel}")

# The fingerprint accounts for the target name, ovpn-backports HEAD commit,
# and the kernel release selected from the target rootfs.
fingerprint_metadata=$(cat <<-EOF
target=${target}
repo=${repo_sha}
kernel=${kernel_release}
EOF
)

# Print the human readable metadata into the logs.
printf '%s\n' "${fingerprint_metadata}" >&2
# Let the workflow capture the hash.
printf '%s\n' "${fingerprint_metadata}" | sha256sum | awk '{ print $1 }'
