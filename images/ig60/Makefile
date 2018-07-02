export PLATFORM = ig60
export PRODUCT = ig60
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
