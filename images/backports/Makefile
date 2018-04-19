export PLATFORM = backports
export PRODUCT = backports
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" backports
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
