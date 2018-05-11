export PLATFORM = backports
export PRODUCT = backports
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" backports
	rm -f latest
	ln -s "$(DATE)" latest
	cp latest/laird-backport-*.tar.bz2 $(BR2_DL_DIR)/$(PRODUCT)-laird-$(LAIRD_RELEASE_STRING).tar.bz2

.PHONY: all
