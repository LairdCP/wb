
# PRODUCT must be set to wb40n or wb45n

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR = ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

USERBIN_EXISTS := $(shell [ -e $(IMAGES)/userfs.bin ] && echo 1 || echo 0)
SQROOT_EXISTS := $(shell [ -e $(IMAGES)/sqroot.bin ] && echo 1 || echo 0)

legal-info:
	rsync -a --exclude=sources $(TOPDIR)/buildroot/output/$(PRODUCT)/legal-info/ ./legal-info-$(DATE)
	tar cjf legal-info-$(DATE).tar.bz ./legal-info-$(DATE)
	rm -f latest.tar.bz
	ln -s legal-info-$(DATE).tar.bz latest.tar.bz
	rm -rf ./legal-info-$(DATE)

copyall:
	cp $(IMAGES)/at91bs.bin .
	cp $(IMAGES)/u-boot.bin .
	cp $(IMAGES)/kernel.bin .
	cp $(IMAGES)/rootfs.bin .
	cp $(IMAGES)/fw_update .
	cp $(IMAGES)/fw_select .
	cp $(IMAGES)/fw_usi .
	cp $(IMAGES)/fw.txt .
	cp $(IMAGES)/rootfs.tar .
	rm -f rootfs.tar.bz2
	bzip2 rootfs.tar

all: copyall

ifeq ($(USERBIN_EXISTS),1)
	cp $(IMAGES)/userfs.bin .
endif

ifeq ($(SQROOT_EXISTS),1)
	cp $(IMAGES)/sqroot.bin .
endif

.PHONY: all copyall legal-info

