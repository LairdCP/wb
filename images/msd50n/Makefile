export PLATFORM = msd50n
export PRODUCT = msd50n
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/$(PRODUCT).tar.bz2 $(DATE)/
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
