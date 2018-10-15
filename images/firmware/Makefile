export PLATFORM = firmware
export PRODUCT = firmware
export DATE := $(shell date "+%Y%m%d")

BR2_DL_DIR ?= ../../archive

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" firmware
	rm -f latest
	ln -s "$(DATE)" latest
	cp latest/* $(BR2_DL_DIR)/ -fr
endif
