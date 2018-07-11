PLATFORM = lrd-network-manager-src
PRODUCT = lrd-network-manager-src
DATE = $(shell date "+%Y%m%d")
ifndef LAIRD_RELEASE_STRING
LAIRD_RELEASE_STRING := $(DATE)
endif
GITDIR=../../buildroot/package/lrd/externals/lrd-network-manager

all:
	mkdir -p $(DATE)
	echo LAIRD_RELEASE_STRING: $(LAIRD_RELEASE_STRING)
	echo GITDIR: $(GITDIR)
	git -C $(GITDIR) archive --format=tar \
	--prefix=lrd-network-manager-$(LAIRD_RELEASE_STRING)/ HEAD \
	| xz -z > "$(DATE)/$(PRODUCT).tar.xz"
	rm -f latest
	ln -s "$(DATE)" latest

.PHONY: all
