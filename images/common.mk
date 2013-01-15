
# PRODUCT must be set to wb40n or wb45n

URL = http://$(shell hostname)/wb/$(PRODUCT)

IMAGES = ../../buildroot/output/$(PRODUCT)/images

fw.txt: kernel.bin rootfs.bin bootstrap.bin u-boot.bin
	echo -n > $@
	echo "$(URL)/bootstrap.bin `md5sum bootstrap.bin | cut -d ' ' -f 1`" >> $@
	echo "$(URL)/u-boot.bin    `md5sum u-boot.bin    | cut -d ' ' -f 1`" >> $@
	echo "$(URL)/kernel.bin    `md5sum kernel.bin    | cut -d ' ' -f 1`" >> $@
	echo "$(URL)/rootfs.bin    `md5sum rootfs.bin    | cut -d ' ' -f 1`" >> $@

kernel.bin: $(IMAGES)/uImage
	cp $+ $@

rootfs.bin: $(IMAGES)/rootfs.ubi
	cp $+ $@

bootstrap.bin: $(IMAGES)/$(PRODUCT).bin
	cp $+ $@

u-boot.bin: $(IMAGES)/u-boot.bin
	cp $+ $@

clean:
	rm -f bootstrap.bin u-boot.bin kernel.bin rootfs.bin fw.txt

.PHONY: clean

