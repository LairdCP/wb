export PRODUCT = reglwb5
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p $(DATE)
	cp -f ../../buildroot/output/$(PRODUCT)/images/* $(DATE)/
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
