export PLATFORM = som60sd_mfg
export PRODUCT = som60sd_mfg
export DATE := $(shell date "+%Y%m%d")

legal-info:
	mkdir -p "legal-info/legal-info-$(DATE)"
	$(MAKE) -f ../../common.mk -C "legal-info" legal-info

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all legal-info
