#!/bin/bash

set -e

KERNEL_REPO_URL='https://github.com/OpenVPN/ovpn-net-next.git'
KERNEL_COMMIT=${KERNEL_COMMIT:-'f2dfcc4b4bc28ba8ad45bce43ad76fa9575e27f5'}
KERNEL_DIR="$PWD/kernel"
ORIG_SOURCES_DIR=${ORIG_SOURCES_DIR:-kernel/drivers/net/ovpn}
ORIG_TESTS_DIR=${ORIG_TESTS_DIR:-kernel/tools/testing/selftests/net/ovpn}
ORIG_YNL_DIR=${ORIG_YNL_DIR:-kernel/tools/net/ynl/pyynl}
MOD_SOURCES_DIR=drivers/net/ovpn
MOD_TESTS_DIR=tools/testing/selftests/net/ovpn
MOD_YNL_DIR=tools/net/ynl/pyynl

clean_ovpn_selftests() {
	rm -fr \
		"$PWD/tools/testing/selftests/net/ovpn" \
		"$PWD/tools/testing/selftests/kselftest" \
		"$PWD/tools/testing/selftests/Makefile" \
		"$PWD/tools/testing/selftests/lib.mk" \
		"$PWD/tools/testing/selftests/kselftest.h" \
		"$PWD/tools/testing/selftests/kselftest_harness.h" \
		"$PWD/tools/testing/selftests/run_kselftest.sh" \
		"$PWD/tools/net/ynl/pyynl" \
		"$PWD/Documentation/netlink/specs/ovpn.yaml" \
		"$PWD/Documentation/netlink/genetlink.yaml" \
		"$PWD/scripts/subarch.include"
}

import_ovpn_selftests() {
	echo "Extracting ovpn selftests"
	clean_ovpn_selftests
	mkdir -p \
		"$PWD/tools/testing/selftests/net" \
		"$PWD/tools/net/ynl" \
		"$PWD/Documentation/netlink/specs" \
		"$PWD/scripts"

	cp -r "$KERNEL_DIR/tools/testing/selftests/net/ovpn" \
		"$PWD/tools/testing/selftests/net/"
	cp -r "$KERNEL_DIR/tools/testing/selftests/kselftest" \
		"$PWD/tools/testing/selftests/"
	cp "$KERNEL_DIR/tools/testing/selftests/Makefile" \
		"$PWD/tools/testing/selftests/Makefile"
	cp "$KERNEL_DIR/tools/testing/selftests/lib.mk" \
		"$PWD/tools/testing/selftests/lib.mk"
	cp "$KERNEL_DIR/tools/testing/selftests/kselftest.h" \
		"$PWD/tools/testing/selftests/kselftest.h"
	cp "$KERNEL_DIR/tools/testing/selftests/kselftest_harness.h" \
		"$PWD/tools/testing/selftests/kselftest_harness.h"
	cp "$KERNEL_DIR/tools/testing/selftests/run_kselftest.sh" \
		"$PWD/tools/testing/selftests/run_kselftest.sh"
	cp -r "$KERNEL_DIR/tools/net/ynl/pyynl" "$PWD/tools/net/ynl/"
	cp "$KERNEL_DIR/Documentation/netlink/specs/ovpn.yaml" \
		"$PWD/Documentation/netlink/specs/ovpn.yaml"
	cp "$KERNEL_DIR/Documentation/netlink/genetlink.yaml" \
		"$PWD/Documentation/netlink/genetlink.yaml"
	cp "$KERNEL_DIR/scripts/subarch.include" "$PWD/scripts/subarch.include"

}

apply_compat_patches() {
	local import_tests=$1
	local patch
	local patches=()

	# without nullglob, an unmatched pattern is passed through literally
	for patch in "$PWD"/compat-patches/sources/*.patch; do
		[ -e "$patch" ] || continue
		patches+=("$patch")
	done

	if [ "$import_tests" -eq "1" ]; then
		for patch in "$PWD"/compat-patches/tests/*.patch \
			"$PWD"/compat-patches/ynl/*.patch; do
			[ -e "$patch" ] || continue
			patches+=("$patch")
		done
	fi

	if [ "${#patches[@]}" -gt "0" ]; then
		# a single invocation validates the entire series before
		# modifying the files
		git apply --verbose "${patches[@]}"
	fi
}

is_kernel_build_artifact() {
	case "$1" in
	*.ko | *.mod | *.mod.c | *.o | Module.symvers | modules.order)
		return 0
		;;
	esac

	return 1
}

write_diff() {
	local old_file=$1
	local new_file=$2
	local output=$3
	local status=0

	# exit status 1 means a diff was produced; only propagate actual errors
	git diff --no-index "$old_file" "$new_file" > "$output" || status=$?
	if [ "$status" -ne "1" ]; then
		return "$status"
	fi
}

generate_patch_set() (
	local orig_dir=$1
	local mod_dir=$2
	local output_dir=$3
	local escaped_orig_dir=${orig_dir#/}
	local escaped_mod_dir=${mod_dir#/}
	local base filepath output patch_name relative_path

	escaped_orig_dir=${escaped_orig_dir//\//\\/}
	escaped_mod_dir=${escaped_mod_dir//\//\\/}
	mkdir -p "$output_dir"

	# recurse into trees such as pyynl/lib, and make an empty tree expand
	# to nothing instead of a literal **/* path. The subshell scopes both
	# options.
	shopt -s globstar nullglob

	for filepath in "$orig_dir"/**/*; do
		[ -f "$filepath" ] || continue
		relative_path=${filepath#"$orig_dir"/}
		# patch dirs are flat, so encode subdirs in the name
		patch_name=${relative_path//\//-}.patch
		output="$output_dir/$patch_name"

		if [ -f "$mod_dir/$relative_path" ]; then
			write_diff "$filepath" "$mod_dir/$relative_path" "$output"
			if [ ! -s "$output" ]; then
				rm -f "$output"
				continue
			fi
			sed -i "s/$escaped_orig_dir/$escaped_mod_dir/" "$output"
		fi
	done

	for filepath in "$mod_dir"/**/*; do
		[ -f "$filepath" ] || continue
		relative_path=${filepath#"$mod_dir"/}
		base=$(basename "$filepath")
		# catch Kbuild output files
		if [ -e "$orig_dir/$relative_path" ] || is_kernel_build_artifact "$base"; then
			continue
		fi
		# catch bin files (such as .pyc) reported as "- -" by numstat
		if git diff --no-index --numstat /dev/null "$filepath" | \
			grep -q '^-[[:space:]]\+-[[:space:]]'; then
			continue
		fi

		patch_name=${relative_path//\//-}.patch
		write_diff /dev/null "$filepath" "$output_dir/$patch_name"
	done
)

replace_patch_set() {
	local generated_dir=$1
	local patch_dir=$2
	local patch

	mkdir -p "$patch_dir"
	rm -f "$patch_dir"/*.patch
	# without nullglob, an unmatched pattern is passed through literally
	for patch in "$generated_dir"/*.patch; do
		[ -e "$patch" ] || continue
		cp "$patch" "$patch_dir/"
	done
}

check_resolved_sources() {
	local path
	local unresolved=0

	for path in "$MOD_SOURCES_DIR" "$MOD_TESTS_DIR" "$MOD_YNL_DIR"; do
		[ -d "$path" ] || continue
		if find "$path" -type f -name '*.rej' -print | grep -q .; then
			echo "Unresolved reject files found under $path" >&2
			unresolved=1
		fi
		if grep -RIlE '^(<<<<<<< |=======|>>>>>>> )' "$path" | grep -q .; then
			echo "Unresolved conflict markers found under $path" >&2
			unresolved=1
		fi
	done

	[ "$unresolved" -eq "0" ]
}

refresh_patches() (
	local tmp_dir

	if [ ! -d "$ORIG_SOURCES_DIR" ] || [ ! -d "$MOD_SOURCES_DIR" ]; then
		echo "Original and modified ovpn sources are required" >&2
		return 1
	fi
	check_resolved_sources

	tmp_dir=$(mktemp -d "$PWD/.compat-patches.XXXXXX")
	trap 'rm -rf "$tmp_dir"' EXIT

	generate_patch_set "$ORIG_SOURCES_DIR" "$MOD_SOURCES_DIR" \
		"$tmp_dir/sources"
	if [ -d "$MOD_TESTS_DIR" ]; then
		generate_patch_set "$ORIG_TESTS_DIR" "$MOD_TESTS_DIR" \
			"$tmp_dir/tests"
	fi
	if [ -d "$MOD_YNL_DIR" ]; then
		generate_patch_set "$ORIG_YNL_DIR" "$MOD_YNL_DIR" \
			"$tmp_dir/ynl"
	fi

	replace_patch_set "$tmp_dir/sources" compat-patches/sources
	if [ -d "$MOD_TESTS_DIR" ]; then
		replace_patch_set "$tmp_dir/tests" compat-patches/tests
	fi
	if [ -d "$MOD_YNL_DIR" ]; then
		replace_patch_set "$tmp_dir/ynl" compat-patches/ynl
	fi
)

get_ovpn() {
	keep=$1
	import_tests=$2

	if [[ ! -d $KERNEL_DIR ]]; then
		git clone --depth 1 "$KERNEL_REPO_URL" "$KERNEL_DIR"
	fi

	echo "Checking out commit $KERNEL_COMMIT"
	git -C "$KERNEL_DIR" fetch --depth 1 origin "$KERNEL_COMMIT"
	git -C "$KERNEL_DIR" reset --hard "$KERNEL_COMMIT"

	echo "Extracting ovpn source files"
	rm -fr "$PWD/drivers/" "$PWD/include/"
	clean_ovpn_selftests
	mkdir -p "$PWD/drivers/net" "$PWD/include/uapi/linux"
	cp -r "$KERNEL_DIR/drivers/net/ovpn" "$PWD/drivers/net/"
	cp "$KERNEL_DIR/include/uapi/linux/ovpn.h" "$PWD/include/uapi/linux/ovpn.h"

	if [ "$import_tests" -eq "1" ]; then
		import_ovpn_selftests
	fi

	apply_compat_patches "$import_tests"

	# We extract the branch from backports because all the non-sources branches
	# of this repo point directly to the corresponding branch in ovpn-net-next
	# and there's no way of getting this info from ovpn-net-next since it has
	# been cloned with --depth 1.
	branch=$(git rev-parse --abbrev-ref HEAD)

	# Save version information to a file (as key=value pairs) unless we're in a
	# sources branch.
	if [[ $branch != *'sources'* ]]; then
		echo "Setting version information"

		# Name of the repository from where the ovpn sources were extracted.
		tree=$(basename "$(git -C "$KERNEL_DIR" config --get remote.origin.url)" | cut -d. -f1)

		# Version of the kernel from where the ovpn sources were extracted.
		kernel_version=$(make -s -C "$KERNEL_DIR" kernelversion)

		# This indirectly indicates also the ovpn-net-next commit used for
		# generating the backports.
		backports_commit=$(git rev-parse --short HEAD)

		rm -f "$PWD/.version"
		cat << EOF > "$PWD/.version"
tree=${tree}
branch=${branch}
kernel_version=${kernel_version}
backports_commit=${backports_commit}
EOF
	fi

	if [ "$keep" -eq "0" ] ; then
		echo "Cleaning up"
		rm -rf "$KERNEL_DIR"
	fi
}

print_usage() {
	echo "Usage: ./backports-ctl.sh <get-ovpn|refresh-patches|clean>"
	echo "       ./backports-ctl.sh get-ovpn [-k|--keep] [-t|--tests]"
	exit 1
}

if ! git --version >/dev/null 2>&1; then
	echo "git could not be found"
	exit 1
fi

command="$1"
if [[ -z $command || $command = "help" ]]; then
	print_usage
elif [ "$command" = "get-ovpn" ]; then
	shift
	keep=0
	import_tests=0
	while [ "$#" -gt 0 ]; do
		case "$1" in
		-k|--keep)
			keep=1
			;;
		-t|--tests)
			import_tests=1
			;;
		*)
			print_usage
			;;
		esac
		shift
	done
	get_ovpn "$keep" "$import_tests"
elif [ "$command" = "refresh-patches" ]; then
	refresh_patches
elif [ "$command" = "clean" ]; then
	read -r -p "Are you sure you want to restore the repository to its default state? [y/N]" clean && [[ "$clean" = "y" || "$clean" = "Y" ]] && git clean -fdx && git reset --hard
else
	echo "Unknown command $command"
	print_usage
fi
