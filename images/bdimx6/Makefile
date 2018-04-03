export PLATFORM = bdimx6
export PRODUCT = bdimx6
export DATE := $(shell date "+%Y%m%d")

legal-info:
	mkdir -p "legal-info/legal-info-$(DATE)"
	$(MAKE) -f ../../common.mk -C "legal-info" legal-info

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" bdimx6
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
