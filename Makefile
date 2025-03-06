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

# REVISION= $(shell	if [ -d "$(PWD)/.git" ]; then \
# 				echo $$(git --git-dir="$(PWD)/.git" describe --always --dirty --match "v*" |sed 's/^v//' 2> /dev/null || echo "[unknown]"); \
# 			fi)

ifneq ("$(wildcard $(KERNEL_SRC)/include/generated/uapi/linux/suse_version.h)","")
VERSION_INCLUDE = -include linux/suse_version.h
endif

NOSTDINC_FLAGS += \
	-I$(PWD)/compat-include/ \
	-I$(PWD)/include/ \
	-include $(PWD)/linux-compat.h \
	$(CFLAGS)

ifneq ($(REVISION),)
NOSTDINC_FLAGS += -DOVPN_VERSION=\"$(REVISION)\"
endif

obj-y += drivers/net/ovpn/
export ovpn

BUILD_FLAGS := \
	M=$(PWD) \
	PWD=$(PWD) \
	REVISION=$(REVISION) \
	CONFIG_OVPN=m \
	INSTALL_MOD_DIR=updates/

all:
	$(MAKE) -C $(KERNEL_SRC) $(BUILD_FLAGS) modules

clean:
	$(MAKE) -C $(KERNEL_SRC) $(BUILD_FLAGS) clean

install:
	$(MAKE) -C $(KERNEL_SRC) $(BUILD_FLAGS) modules_install
	$(DEPMOD)

.PHONY: all clean install

