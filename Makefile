PWD:=$(shell pwd)
KERNEL_SRC ?= /lib/modules/$(shell uname -r)/build

ifeq ($(shell cd $(KERNEL_SRC) && pwd),)
$(error $(KERNEL_SRC) is missing, please set KERNEL_SRC)
endif

export KERNEL_SRC
RM ?= rm -f
CP := cp -fpR
LN := ln -sf
DEPMOD := depmod -a

ifneq ("$(wildcard $(KERNEL_SRC)/include/generated/uapi/linux/suse_version.h)","")
VERSION_INCLUDE = -include linux/suse_version.h
endif

# extract values from .version and construct the module version string
ifneq ("$(wildcard $(PWD)/.version)","")
    tree             := $(shell . $(PWD)/.version && echo $$tree)
    branch           := $(shell . $(PWD)/.version && echo $$branch)
    kernel_version   := $(shell . $(PWD)/.version && echo $$kernel_version)
    backports_commit := $(shell . $(PWD)/.version && echo $$backports_commit)
    version_str      := $(tree)/$(branch)-$(kernel_version)-$(backports_commit)
    CFLAGS           += -DOVPN_MODULE_VERSION=\"$(version_str)\"
else
    $(warning '.version' file not found — have you run 'backports-ctl.sh get-ovpn'?)
endif

NOSTDINC_FLAGS += \
	-I$(PWD)/compat-include/ \
	-I$(PWD)/include/ \
	-include $(PWD)/linux-compat.h \
	$(CFLAGS)

obj-y += drivers/net/ovpn/
export ovpn

BUILD_FLAGS := \
	M=$(PWD) \
	PWD=$(PWD) \
	CONFIG_OVPN=m \
	CFLAGS_MODULE="-DDEBUG" \
	INSTALL_MOD_DIR=updates/

all:
	$(MAKE) -C $(KERNEL_SRC) $(BUILD_FLAGS) modules

clean:
	$(MAKE) -C $(KERNEL_SRC) $(BUILD_FLAGS) clean
	$(MAKE) -C $(PWD)/tests/ovpn-cli $(BUILD_FLAGS) clean

install: all
	$(MAKE) -C $(KERNEL_SRC) $(BUILD_FLAGS) modules_install
	$(DEPMOD)

ovpn-cli:
	$(MAKE) -C $(PWD)/tests/ovpn-cli $(BUILD_FLAGS) ovpn-cli

.PHONY: all clean install ovpn-cli

