
# PRODUCT must be set to wb40n or wb45n or bdimx6

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR ?= ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

USERBIN_EXISTS := $(shell [ -e $(IMAGES)/userfs.bin ] && echo 1 || echo 0)
SQROOT_EXISTS := $(shell [ -e $(IMAGES)/sqroot.bin ] && echo 1 || echo 0)
BOOTSTRAP_EXISTS := $(shell [ -e $(IMAGES)/at91bs.bin ] && echo 1 || echo 0)
UBOOT_EXISTS := $(shell [ -e $(IMAGES)/u-boot.bin ] && echo 1 || echo 0)
SWU_EXISTS := $(shell [ -e $(IMAGES)/*_$(DATE).swu ] && echo 1 || echo 0)

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

ifeq ($(PRODUCT),$(filter wb45n_legacy wb50n_legacy wb50n_rdvk,$(PRODUCT)))
FILES += fw_update fw_select fw_usi fw.txt
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

all: copyall

.PHONY: all copyall bdimx6 legal-info

