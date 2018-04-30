
# PRODUCT must be set to bdimx6 or backports

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR ?= ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

USERBIN_EXISTS := $(shell [ -e $(IMAGES)/userfs.bin ] && echo 1 || echo 0)
SQROOT_EXISTS := $(shell [ -e $(IMAGES)/sqroot.bin ] && echo 1 || echo 0)
BOOTSTRAP_EXISTS := $(shell [ -e $(IMAGES)/at91bs.bin ] && echo 1 || echo 0)
UBOOT_EXISTS := $(shell [ -e $(IMAGES)/u-boot.bin ] && echo 1 || echo 0)
SWU_EXISTS := $(shell [ -e $(IMAGES)/*_$(DATE).swu ] && echo 1 || echo 0)

FW_UPDATE_EXISTS := $(shell [ -e $(IMAGES)/fw_update ] && echo 1 || echo 0)
FW_SELECT_EXISTS := $(shell [ -e $(IMAGES)/fw_select ] && echo 1 || echo 0)
FW_USI_EXISTS := $(shell [ -e $(IMAGES)/fw_usi ] && echo 1 || echo 0)
FW_TXT_EXISTS := $(shell [ -e $(IMAGES)/fw.txt ] && echo 1 || echo 0)

# General files
FILES := kernel.bin rootfs.bin rootfs.tar

ifeq ($(BOOTSTRAP_EXISTS),1)
FILES += at91bs.bin
endif

ifeq ($(UBOOT_EXISTS),1)
FILES += u-boot.bin
endif

ifeq ($(USERBIN_EXISTS),1)
FILES += userfs.bin
endif

ifeq ($(SQROOT_EXISTS),1)
FILES += sqroot.bin
endif

ifeq ($(SWU_EXISTS),1)
FILES += *_$(DATE).swu
endif

ifeq ($(FW_UPDATE_EXISTS),1)
FILES += fw_update
endif

ifeq ($(FW_SELECT_EXISTS),1)
FILES += fw_select
endif

ifeq ($(FW_USI_EXISTS),1)
FILES += fw_usi
endif

ifeq ($(FW_TXT_EXISTS),1)
FILES += fw.txt
endif

legal-info:
	rsync -a --exclude=sources $(TOPDIR)/buildroot/output/$(PRODUCT)/legal-info/ ./legal-info-$(DATE)
	tar cjf legal-info-$(DATE).tar.bz ./legal-info-$(DATE)
	rm -f latest.tar.bz
	ln -s legal-info-$(DATE).tar.bz latest.tar.bz
	rm -rf ./legal-info-$(DATE)

copyall:
	$(foreach FILE,$(FILES), cp $(IMAGES)/$(FILE) .;)
	rm -f rootfs.tar.bz2
	bzip2 rootfs.tar

bdimx6:
	cp $(IMAGES)/sdcard.img . -fr

backports:
	cp $(IMAGES)/laird-backport.tar.bz2 laird-backport.tar.bz2 -fr

all: copyall

.PHONY: all copyall bdimx6 backports
