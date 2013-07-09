export PLATFORM = wb45n
export PRODUCT = wb45n_devel
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)"
	ln -sf "$(DATE)/fw.txt" fw.txt
	ln -sf "$(DATE)" latest

.PHONY: all
