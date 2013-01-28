
# PRODUCT must be set to wb40n or wb45n

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR = ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

all: fw.txt fw_update fw_select

fw_%: $(TOPDIR)/buildroot/board/sdc/rootfs-additions-common/usr/sbin/fw_%
	cp $+ $@

fw.txt: kernel.bin rootfs.bin bootstrap.bin u-boot.bin
	$(TOPDIR)/images/mkfwtxt.sh $(URL)

kernel.bin: $(IMAGES)/uImage
	cp $+ $@

rootfs.bin: $(IMAGES)/rootfs.ubi
	cp $+ $@

bootstrap.bin: $(IMAGES)/$(PRODUCT).bin
	cp $+ $@

u-boot.bin: $(IMAGES)/u-boot.bin
	cp $+ $@

.PHONY: all

