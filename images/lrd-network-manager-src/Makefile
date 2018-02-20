PLATFORM = lrd-network-manager-src
PRODUCT = lrd-network-manager-src
DATE = $(shell date "+%Y%m%d")
ifndef LAIRD_RELEASE_STRING
LAIRD_RELEASE_STRING := $(DATE)
endif
GITDIR=../../buildroot/package/lrd/externals/lrd-network-manager

all: git-archive
	mkdir -p $(DATE)
	tar --transform "s,^,$(PRODUCT)-$(LAIRD_RELEASE_STRING)/," \
	-cf "$(DATE)/$(PRODUCT).tar" $(PRODUCT).tar
	bzip2 -f "$(DATE)/$(PRODUCT).tar"
	rm -f latest
	ln -s "$(DATE)" latest

git-archive:
	echo LAIRD_RELEASE_STRING: $(LAIRD_RELEASE_STRING)
	echo GITDIR: $(GITDIR)
	git -C $(GITDIR) archive --format=tar \
	--prefix=lrd-network-manager/ HEAD \
	> $(PRODUCT).tar

.PHONY: all git-archive
