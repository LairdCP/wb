export PLATFORM = msd45n
export PRODUCT = reg45n
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/* $(DATE)/
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	rm $(DATE)/host-sbom $(DATE)/target-sbom
	rm $(DATE)/host-cve.xml $(DATE)/target-cve.xml
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
