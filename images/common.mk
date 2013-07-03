
# PRODUCT must be set to wb40n or wb45n

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR = ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

fw.txt: copyall
	$(TOPDIR)/buildroot/board/sdc/mkfwtxt.sh $(URL)/$(DATE)

copyall:
	cp $(IMAGES)/kernel.bin .
	cp $(IMAGES)/rootfs.bin .
	cp $(IMAGES)/u-boot.bin .
	cp $(IMAGES)/bootstrap.bin .
	cp $(IMAGES)/fw_update .
	cp $(IMAGES)/fw_select .

.PHONY: all copyall

