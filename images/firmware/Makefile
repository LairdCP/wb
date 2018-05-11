export PLATFORM = firmware
export PRODUCT = firmware
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" firmware
	rm -f latest
	ln -s "$(DATE)" latest
