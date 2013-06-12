export PLATFORM = msd45n
export PRODUCT = msd45n_fips
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/$(PLATFORM).tar.bz2 $(DATE)/

.PHONY: all
