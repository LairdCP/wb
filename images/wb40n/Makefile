export PRODUCT = wb40n
DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)"
	ln -sf "$(DATE)/fw.txt" fw.txt

.PHONY: all
