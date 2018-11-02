export PLATFORM = som60sd_mfg
export PRODUCT = som60sd_mfg
export DATE := $(shell date "+%Y%m%d")

# Have ../../common.mk copy some extra files we want in this specific build
export EXTRA_FILES := mksdcard.sh mksdimg.sh u-boot-spl.bin rootfs.tar

legal-info:
	mkdir -p "legal-info/legal-info-$(DATE)"
	$(MAKE) -f ../../common.mk -C "legal-info" legal-info

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	$(MAKE) -f ../../common.mk -C "$(DATE)" sbom
	$(MAKE) -f ../../common.mk -C "$(DATE)" cve
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all legal-info
