# Out-of-tree backports for the ovpn kernel module

The ovpn kernel module is part of the Linux kernel starting from version 6.15. It enhances OpenVPN performance by offloading data channel management to the kernel. This repository contains out-of-tree backports for the ovpn kernel module, enabling its use with older kernel versions.

## Installation

### Pre-patched sources

A pre-patched version of the source files is available for download in the [tags](https://github.com/OpenVPN/ovpn-backports/tags) section of this repository. After downloading, you can simply run `make && make install` to build and install the module.

### Building from source

#### Preparing the build environment

To build the module, you need the kernel headers (or sources) and the ovpn source files. You can either compile the module against your currently running kernel (by ensuring the headers are installed) or against a different kernel version by providing the appropriate path to the kernel sources.

The first step is to get the latest ovpn sources through the utility script `backports-ctl.sh`:

```sh
./backports-ctl.sh get-ovpn
```

Be aware that this command temporarily downloads a full kernel tree, extracts the ovpn files from it, and applies patches. If you want the kernel repository to persist, run the command with the `--keep` (or `-k`) option. This option keeps the repository in the `kernel` directory as a shallow copy, and subsequent runs will simply update it.

Additionally you can restore the repository to its original state with:

```sh
./backports-ctl.sh clean
```

#### Building and installing

To build the ovpn kernel module, just type:

```sh
make
```

in the root folder. The Makefile will autodetect your running kernel and will try to use its headers to get the code compiled.

If you want to build ovpn against a kernel different from the one running on the host, run:

```sh
make KERNEL_SRC=/path/to/the/kernel/tree
```

The control is passed to the kernel Makefile, therefore any kernel Makefile argument can be specified on the command line and it will be passed automatically. Once done building, executing the command:

```sh
make install
```

will install the ovpn.ko kernel module in the updates/ subfolder of the kernel modules directory on your system. It normally means `/lib/modules/$(uname -r)/updates/`.

> **_NOTE:_** If Secure Boot is enabled, you need to sign the module before loading it. Check [this](https://askubuntu.com/questions/760671/could-not-load-vboxdrv-after-upgrade-to-ubuntu-16-04-and-i-want-to-keep-secur/768310#768310) tutorial on how to sign a custom kernel module.

## Testing

The module should successfully load and run kernel selftests on the following distributions:
 - Ubuntu 20.04
 - Ubuntu 22.04
 - Debian 12.10
 - Debian 11.6
 - RHEL 10.0
 - RHEL 9.0 - 9.5
 - RHEL 8.10
