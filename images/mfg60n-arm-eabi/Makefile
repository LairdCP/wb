export PRODUCT = mfg60n-arm-eabi
export DATE := $(shell date "+%Y%m%d")

ifneq ($(wildcard ../../buildroot/output/$(PRODUCT)/images/*.sh),)
DEP=mfg60n_vendor
endif

mfg60n_vendor:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/* $(DATE)/
	rm -f latest
	ln -s "$(DATE)" latest

all: $(DEP)

.PHONY: all mfg60n_vendor
