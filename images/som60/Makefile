export PLATFORM = som60
export PRODUCT = som60
export DATE := $(shell date "+%Y%m%d")

legal-info:
	mkdir -p "legal-info/legal-info-$(DATE)"
	$(MAKE) -f ../../common.mk -C "legal-info" legal-info

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	$(MAKE) -f ../../common.mk -C "$(DATE)" sdk
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all legal-info
