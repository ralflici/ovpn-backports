# Out-of-tree backports for the ovpn kernel module

The ovpn kernel module is part of the Linux kernel starting from version 6.15. It enhances OpenVPN performance by offloading data channel management to the kernel. This repository contains out-of-tree backports for the ovpn kernel module, enabling its use with older kernel versions.

## Preparing the build environment

To build the module, you need the kernel headers (or sources) and the ovpn source files. You can either compile the module against your currently running kernel (by ensuring the headers are installed) or against a different kernel version by providing the appropriate path to the kernel sources.

A utility script (`backports-ctl.sh`) is provided to assist with these steps. It can download kernel sources, ovpn sources, and prepare the build. The first step is to download the latest ovpn sources:

```sh
./backports-ctl.sh get-ovpn
```

This command downloads the latest `net-next` kernel repository, extracts the ovpn files from it, and patches them. If you prefer to use a different ovpn version (not recommended), you can manually provide the `include/uapi/linux/ovpn.h` header and the `drivers/net/ovpn/` directory. Keep in mind that you might need to adjust the sources to ensure compatibility with your target kernel version.

If you want to compile the module for a kernel version other than your currently running kernel, you can download its sources with:

```sh
./backports-ctl.sh get-kernel M.m
```

Here, `M.m` represents the kernel version you want to compile the module against. This command clones the mainline kernel repository with the `--depth 1` option and prepares it for the build. If you decide to change the version later, re-running the command will clean the repository, fetch the new target with `--depth 1`, and switch to it. Alternatively, you can provide the path to the kernel sources manually during the build.
You can optionally provide a `.config` file as the last argument to the command; if no file is specified, the one relative to the currently running kernel will be used by default.
Alternatively, if you are compiling for the currently running kernel, you must have the kernel sources installed in the default location.

Finally you can restore the repository to its original state with:

```sh
./backports-ctl.sh clean
```

## Building and installing

Once the sources are ready, you can build the module with:

```sh
make KERNEL_SRC=/path/to/kernel
```

> **_NOTE:_** If you're building against a kernel version different from your currently running one, the `Module.symvers` file won't be generated unless you compile the kernel (or its modules) first.

If you are compiling against the currently running kernel you can omit the `KERNEL_SRC` parameter. In this case you may also want to install the module by running:

```sh
make install
```

> **_NOTE:_** If Secure Boot is enabled, you need to sign the module before loading it. Check [this](https://askubuntu.com/questions/760671/could-not-load-vboxdrv-after-upgrade-to-ubuntu-16-04-and-i-want-to-keep-secur/768310#768310) tutorial on how to sign a custom kernel module.

## Supported distros

Tested on:
 - Ubuntu 20.04
 - Ubuntu 22.04
 - Debian 12.10
 - RHEL 10.0
 - RHEL 9.0 - 9.5
 - RHEL 8.10
