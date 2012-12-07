
SERVERNAME = $(shell hostname)
PRODUCT = $(shell cat ../product.selected)
URL = http://$(SERVERNAME)/$(PRODUCT)

IMAGES = ../buildroot/output/images

fw.txt: kernel.bin rootfs.bin bootstrap.bin u-boot.bin
	echo -n > fw.txt
	echo "$(URL)/bootstrap.bin `md5sum bootstrap.bin | cut -d ' ' -f 1`" >> fw.txt
	echo "$(URL)/u-boot.bin    `md5sum u-boot.bin    | cut -d ' ' -f 1`" >> fw.txt
	echo "$(URL)/kernel.bin    `md5sum kernel.bin    | cut -d ' ' -f 1`" >> fw.txt
	echo "$(URL)/rootfs.bin    `md5sum rootfs.bin    | cut -d ' ' -f 1`" >> fw.txt

kernel.bin: $(IMAGES)/uImage
	cp $+ $@

rootfs.bin: $(IMAGES)/rootfs.ubi
	cp $+ $@

bootstrap.bin: $(IMAGES)/$(PRODUCT).bin
	cp $+ $@

u-boot.bin: $(IMAGES)/u-boot.bin
	cp $+ $@
