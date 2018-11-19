export PRODUCT = mfg60n-arm-eabihf
export DATE := $(shell date "+%Y%m%d")

ifneq ($(wildcard ../../buildroot/output/$(PRODUCT)/images/*.sh),)
DEP=mfg60n_vendor
endif

mfg60n_vendor:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/* $(DATE)/
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	rm $(DATE)/host-sbom $(DATE)/target-sbom
	rm $(DATE)/host-cve.xml $(DATE)/target-cve.xml
	rm -f latest
	ln -s "$(DATE)" latest

all: $(DEP)


.PHONY: all mfg60n_vendor
