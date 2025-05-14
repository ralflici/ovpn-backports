#!/bin/bash

set -e

KERNEL_REPO_URL='https://github.com/OpenVPN/ovpn-net-next.git'
KERNEL_COMMIT=${KERNEL_COMMIT:-'476148af4e28f498bf769eeed81ef99728544c56'}
KERNEL_DIR="$PWD/kernel"

get_ovpn() {
	keep=$1

	if [[ ! -d $KERNEL_DIR ]]; then
		git clone --depth 1 $KERNEL_REPO_URL $KERNEL_DIR
	fi

	echo "Checking out commit $KERNEL_COMMIT"
	git -C $KERNEL_DIR fetch --depth 1 origin $KERNEL_COMMIT
	git -C $KERNEL_DIR reset --hard $KERNEL_COMMIT

	echo "Extracting ovpn source files"
	rm -fr $PWD/drivers/ $PWD/include/
	mkdir -p $PWD/drivers/net $PWD/include/uapi/linux
	cp -r $KERNEL_DIR/drivers/net/ovpn $PWD/drivers/net/
	cp $KERNEL_DIR/include/uapi/linux/ovpn.h $PWD/include/uapi/linux/ovpn.h

	echo "Applying patch"
	git apply --verbose ovpn.patch

	echo "Adding MODULE_VERSION"
	# Name of the repository from where the ovpn sources were extracted.
	tree=$(basename $(git -C $KERNEL_DIR config --get remote.origin.url) | cut -d. -f1)

	# 'main' or 'development'. We extract this from backports because both
	# branches of this repo point directly to the corresponding branch in
	# ovpn-net-next and there's no way of getting this info from ovpn-net-next
	# since it has been cloned with --depth 1.
	branch=$(git rev-parse --abbrev-ref HEAD)

	# Version of the kernel from where the ovpn sources were extracted.
	kernel_version=$(make -s -C $KERNEL_DIR kernelversion)

	# This indirectly indicates also the ovpn-net-next commit used for
	# generating the backports.
	backports_commit=$(git rev-parse --short HEAD)

	sed -i '/^MODULE_VERSION(/d' $PWD/drivers/net/ovpn/main.c
	version_string="$tree/$branch-$kernel_version-$backports_commit"
	module_version="MODULE_VERSION(\"$version_string\");"
	echo "$module_version" >> $PWD/drivers/net/ovpn/main.c

	# Save the version string for the tag
	echo "$version_string" > $PWD/.version

	if [ "$keep" -eq "0" ] ; then
		echo "Cleaning up"
		rm -rf $KERNEL_DIR
	fi
}

print_usage() {
	echo "Usage: ./backports-ctl.sh <get-ovpn|clean>"
	exit 1
}

if ! git --version 2>&1 >/dev/null; then
	echo "git could not be found"
	exit 1
fi

command="$1"
if [[ -z $command || $command = "help" ]]; then
	print_usage
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
