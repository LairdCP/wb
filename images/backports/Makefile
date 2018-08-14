include ../../laird_version.mk

export PLATFORM = backports
export PRODUCT = backports
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" backports
	rm -f latest
	ln -s "$(DATE)" latest
	cp latest/laird-backport-$(DATE).tar.bz2 $(BR2_DL_DIR)/backports-laird-$(MSD_VERSION).tar.bz2 -fr

.PHONY: all
