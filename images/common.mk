
# PRODUCT must be set to wb40n or wb45n or bdimx6 or backports

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR ?= ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

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

bdimx6:
	cp $(IMAGES)/sdcard.img . -fr

backports:
	cp $(IMAGES)/laird-backport.tar.bz2 laird-backport-$(DATE).tar.bz2 -fr

all: copyall

.PHONY: all copyall bdimx6 backports legal-info
