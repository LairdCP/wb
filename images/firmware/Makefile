export PLATFORM = firmware
export PRODUCT = firmware
export DATE := $(shell date "+%Y%m%d")

BR2_DL_DIR ?= ../../archive

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" firmware
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	rm -f latest
	ln -s "$(DATE)" latest
	cp latest/* $(BR2_DL_DIR)/ -fr
