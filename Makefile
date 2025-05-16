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
	INSTALL_MOD_DIR=updates/

all: ovpn-cli
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

