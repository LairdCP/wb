export PLATFORM = wb45n
export PRODUCT = welch_allyn
export DATE := $(shell date "+%Y%m%d")

all:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)"
	ln -sf "$(DATE)/fw.txt" fw.txt

.PHONY: all
