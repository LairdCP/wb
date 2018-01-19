export PLATFORM = msd45n
export PRODUCT = msd45n
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/$(PRODUCT).tar.bz2 $(DATE)/
	rm -f latest
	ln -s "$(DATE)" latest
	cp latest/$(PRODUCT).tar.bz2 $(BR2_DL_DIR)/$(PRODUCT)-laird-$(LAIRD_RELEASE_STRING).tar.bz2

.PHONY: all
