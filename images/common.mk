
# PRODUCT must be set to wb40n or wb45n or bdimx6 or backports or firmware

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR ?= ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

# General files
FILES := kernel.bin kernel.itb rootfs.bin rootfs.tar rootfs.tar.bz2

# At91bootstrap
FILES += at91bs.bin

# U-Boot SPL
FILES += boot.bin

# U-Boot propper
FILES += u-boot.bin u-boot.itb

# RW User filesystem
FILES += userfs.bin

# RO Squashfs root
FILES += sqroot.bin

# SW Update file
FILES += $(PRODUCT)_$(DATE).swu

# FW_update files
FILES += fw_update fw_select fw_usi fw.txt

legal-info:
	rsync -a --exclude=sources $(TOPDIR)/buildroot/output/$(PRODUCT)/legal-info/ ./legal-info-$(DATE)
	tar cjf legal-info-$(DATE).tar.bz ./legal-info-$(DATE)
	rm -f latest.tar.bz
	ln -s legal-info-$(DATE).tar.bz latest.tar.bz
	rm -rf ./legal-info-$(DATE)

copyall:
	$(foreach FILE,$(FILES), $(shell [ -e $(IMAGES)/$(FILE) ] && cp $(IMAGES)/$(FILE) .))
	$(shell [ -e rootfs.tar.bz2 ] && rm -f rootfs.tar.bz2 && bzip2 rootfs.tar;)

bdimx6:
	cp $(IMAGES)/sdcard.img . -fr

backports:
	cp $(IMAGES)/laird-backport-*.tar.bz2 laird-backport-$(DATE).tar.bz2 -fr

firmware:
	cp $(IMAGES)/*.zip . -fr
	cp $(IMAGES)/laird-60-radio-firmware-*.tar.bz2 . -fr
	cp $(IMAGES)/laird-lwb*.tar.bz2 . -fr

all: copyall

.PHONY: all copyall bdimx6 backports
