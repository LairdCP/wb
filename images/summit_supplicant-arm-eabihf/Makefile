export PLATFORM = summit_supplicant-arm-eabihf
export PRODUCT = summit_supplicant-arm-eabihf
export DATE := $(shell date "+%Y%m%d")

BR2_DL_DIR ?= ../../archive

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/$(PRODUCT).tar.bz2 $(DATE)/
	rm -f latest
	ln -s "$(DATE)" latest
	cp latest/$(PRODUCT).tar.bz2 $(BR2_DL_DIR)/$(PRODUCT)-$(LAIRD_RELEASE_STRING).tar.bz2

.PHONY: all
