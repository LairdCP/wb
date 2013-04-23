export PLATFORM = msd45n
export PRODUCT = msd45n
export DATE := $(shell date "+%Y%m%d")

SYSROOT := ../../buildroot/output/msd45n/host/usr/arm-buildroot-linux-gnueabi/sysroot

all:
	mkdir -p $(DATE)
	cp -f $(SYSROOT)/usr/include/sdc_sdk.h $(DATE)/
	cp -f $(SYSROOT)/usr/include/sdc_events.h $(DATE)/
	cp -f ../../buildroot/output/$(PRODUCT)/images/rootfs.tar.bz2 $(DATE)/$(PRODUCT).tar.bz2

.PHONY: all
