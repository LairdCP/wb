PLATFORM = sterling_supplicant-src
PRODUCT = sterling_supplicant-src
DATE = $(shell date "+%Y%m%d")
ifndef LAIRD_RELEASE_STRING
LAIRD_RELEASE_STRING := $(DATE)
endif
GITDIR=../../buildroot/package/lrd/externals/sterling_supplicant

all:
	echo LAIRD_RELEASE_STRING: $(LAIRD_RELEASE_STRING)
	echo GITDIR: $(GITDIR)
	mkdir -p $(DATE)
	git -C $(GITDIR) archive --format=tar.gz \
	--prefix=sterling_supplicant-$(LAIRD_RELEASE_STRING)/ HEAD \
	README COPYING CONTRIBUTIONS src wpa_supplicant hs20 laird \
	> "$(DATE)/$(PRODUCT).tar.gz"
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
