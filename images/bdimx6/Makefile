export PLATFORM = bdimx6
export PRODUCT = bdimx6
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" bdimx6
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
