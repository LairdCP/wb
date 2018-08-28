export PLATFORM = som60sd
export PRODUCT = som60sd
export DATE := $(shell date "+%Y%m%d")

# Have ../../common.mk copy some extra files we want in this specific build
export EXTRA_FILES := mksdcard.sh mksdimg.sh u-boot-spl.bin rootfs.tar

legal-info:
	mkdir -p "legal-info/legal-info-$(DATE)"
	$(MAKE) -f ../../common.mk -C "legal-info" legal-info

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all legal-info
