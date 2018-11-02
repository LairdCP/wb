export PLATFORM = wb45n
export PRODUCT = wb45n
export DATE := $(shell date "+%Y%m%d")

legal-info:
	mkdir -p "legal-info/legal-info-$(DATE)"
	$(MAKE) -f ../../common.mk -C "legal-info" legal-info

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	ln -sf "$(DATE)/fw.txt" fw.txt
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all legal-info
