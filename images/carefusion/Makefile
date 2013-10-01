export PLATFORM = wb40n
export PRODUCT = carefusion
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)"
	ln -sf "$(DATE)/fw.txt" fw.txt
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
