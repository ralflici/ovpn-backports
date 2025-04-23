#!/bin/bash

set -e

MIN_KERNEL_VERSION='4.18.0'
OVPN_CONFIG_FILE='ovpn.cfg'
KERNEL_REPO_URL='git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git'
# NET_NEXT_REPO_URL='git://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git'
NET_NEXT_REPO_URL='https://github.com/mandelbitdev/ovpn-net-next.git'
DEFAULT_KERNEL_ROOT="/usr/lib/modules/$(uname -r)/build"
DEFAULT_CONFIG_FILE="$DEFAULT_KERNEL_ROOT/.config"

less_then_version() {
	version=$1
	limit=$2

	version_major=$(echo $version | cut -d. -f1)
	version_minor=$(echo $version | cut -d. -f2)
	version_patch=$(echo $version | cut -d. -f3)

	limit_major=$(echo $limit | cut -d. -f1)
	limit_minor=$(echo $limit | cut -d. -f2)
	limit_patch=$(echo $limit | cut -d. -f3)

	if [ $version_major -lt $limit_major ]; then
		return 0
	elif [ $version_major -eq $limit_major ]; then
		if [ $version_minor -lt $limit_minor ]; then
			return 0
		elif [[ $version_minor -eq $limit_minor && ! -z "$version_patch" ]]; then
			if [ $version_patch -lt $limit_patch ]; then
				return 0
			fi
		fi
	fi
	return 1
}

clean_kernel_repo() {
	git -C $PWD/kernel clean -fdx
	git -C $PWD/kernel reset --hard 1>/dev/null
	make mrproper -C $PWD/kernel
}

get_kernel() {
	version="$1"
	config_file="$2"

	if less_then_version $version $MIN_KERNEL_VERSION; then
		echo "Minimum supported version is $MIN_KERNEL_VERSION"
		exit 1
	fi

	if [ -d $PWD/kernel ]; then
		if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			target_tag="v$(echo $version | cut -d. -f1,2)" # Truncate version to major.minor

			clean_kernel_repo
			git -C $PWD/kernel fetch --depth 1 origin tag $target_tag
			git -C $PWD/kernel checkout tags/$target_tag
		else
			echo "Kernel source at $PWD/kernel doesn't appear to be a git repository"
			exit 1
		fi
	else
		echo "Cloning mainline kernel repository"
		git clone --depth 1 --branch v$version $KERNEL_REPO_URL $PWD/kernel
	fi

	echo "Configuring kernel"
	cp $config_file $PWD/kernel/.config
	make olddefconfig -C $PWD/kernel
}

get_ovpn() {
	keep=$1
	if [ -d $PWD/net-next ]; then
		echo "net-next directory already exists"
		exit 1
	fi

	echo "Cloning net-next repository"
	latest_tag=$(git ls-remote --tags $NET_NEXT_REPO_URL | awk -F/ '{print $3}' | sort -V | tail -n1 | sed 's/\^.*//')
	if [ -z "$latest_tag" ]; then # our fork of net-next doesn't have tags
		git clone --depth 1 --single-branch $NET_NEXT_REPO_URL $PWD/net-next
	else
		git clone --depth 1 --branch $latest_tag --single-branch $NET_NEXT_REPO_URL $PWD/net-next
	fi

	echo "Extracting ovpn source files"
	rm -fr $PWD/drivers/ $PWD/include/
	mkdir -p $PWD/drivers/net $PWD/include/uapi/linux
	cp -r $PWD/net-next/drivers/net/ovpn $PWD/drivers/net/
	cp $PWD/net-next/include/uapi/linux/ovpn.h $PWD/include/uapi/linux/ovpn.h

	if [ "$keep" -eq "0" ] ; then
		echo "Cleaning up"
		rm -rf $PWD/net-next
	fi

	echo "Applying patch"
	git apply --verbose ovpn.patch
}

print_usage() {
	echo "Usage: ./backports-ctl.sh <get-kernel|get-ovpn|clean>"
	exit 1
}

if ! git --version 2>&1 >/dev/null; then
	echo "git could not be found"
	exit 1
fi

command="$1"
if [[ -z $command || $command = "help" ]]; then
	print_usage
elif [ $command = "get-kernel" ]; then
	version="$2"
	config_file="$3"
	if [ -z "$version" ]; then
		echo "Usage: $0 get-kernel <version (e.g. $MIN_KERNEL_VERSION)> [config_file]"
		exit 1
	fi
	if [ -z "$config_file" ]; then
		config_file=$DEFAULT_CONFIG_FILE
	fi
	get_kernel $version $config_file
elif [ $command = "get-ovpn" ]; then
	keep="$2"
	if [ -z "$keep" ]; then
		get_ovpn 0
	elif [[ "$keep" = "-k" || "$keep" = "--keep" ]]; then
		get_ovpn 1
	else
		echo "Usage $0 get-ovpn [-k | --keep]"
	fi
elif [ $command = "clean" ]; then
	read -p "Are you sure you want to restore the repository to its default state? [y/N]" clean && [[ "$clean" = "y" || "$clean" = "Y" ]] && git clean -fdx && git reset --hard
else
	echo "Unknown command $command"
	print_usage
fi
