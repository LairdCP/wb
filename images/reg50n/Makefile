export PLATFORM = msd50n
export PRODUCT = reg50n
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/* $(DATE)/
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
