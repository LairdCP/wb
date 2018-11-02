export PLATFORM = sterling_supplicant-x86
export PRODUCT = sterling_supplicant-x86
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/$(PRODUCT).tar.bz2 $(DATE)/
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
