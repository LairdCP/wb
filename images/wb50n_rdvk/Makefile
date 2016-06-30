export PLATFORM = wb50n
export PRODUCT = wb50n_rdvk
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" all
	ln -sf "$(DATE)/fw.txt" fw.txt
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
