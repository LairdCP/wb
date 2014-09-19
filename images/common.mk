
# PRODUCT must be set to wb40n or wb45n

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR = ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

fw.txt: copyall
	$(TOPDIR)/buildroot/board/laird/mkfwtxt.sh $(URL)/$(DATE)

copyall:
	cp $(IMAGES)/at91bs.bin .
	cp $(IMAGES)/u-boot.bin .
	cp $(IMAGES)/kernel.bin .
	cp $(IMAGES)/rootfs.bin .
	cp $(IMAGES)/fw_update .
	cp $(IMAGES)/fw_select .
	cp $(IMAGES)/rootfs.tar .
	rm -f rootfs.tar.bz2
	bzip2 rootfs.tar

all: fw.txt copyall

.PHONY: all copyall legal-info

