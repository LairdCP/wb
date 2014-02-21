# This makefile downloads buildroot from the buildroot website
# and prepares it for Laird WB40/45 building

# if BUILDROOT_DL_DIR is set, archives are downloaded to BUILDROOT_DL_DIR
LAIRD_DL_DIR := archive
ifdef BUILDROOT_DL_DIR
LAIRD_DL_DIR            := $(BUILDROOT_DL_DIR)
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.5.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/msd45n-laird_fips-3.4.2.1.tar.bz2 \
                           archive/msd40n-laird-3.4.2.1.tar.bz2
endif

URL   := http://buildroot.uclibc.org/downloads/
VER   := 2013.02
PKG   := buildroot-$(VER)
ARCHV := $(PKG).tar.bz2

default: wb40n wb45n

all: wb40n wb45n msd40n msd45n

msd40n msd45n msd45n_fips wb40n wb45n wb45n_devel wb40n_devel wb45n_customer: unpack.stamp
        # install the config file
	$(MAKE) O=output/$@ -C buildroot $@_defconfig
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

unpack: unpack.stamp
unpack.stamp:
ifdef BUILDROOT_DL_DIR
        # copy the Laird archives into the override buildroot directory
	cp -n $(LAIRD_ARCHIVES) $(BUILDROOT_DL_DIR)/
	for i in $(LAIRD_ARCHIVES_OPTIONAL); do \
	    test -f $$i && cp -n $$i $(BUILDROOT_DL_DIR)/ || true; \
	done
endif
	cd buildroot/configs && ln -s ../board/laird/customers/wb45n_customer/configs/buildroot.config wb45n_customer_defconfig
        # mark operation as done
	touch unpack.stamp

source-wb40n:
	$(MAKE) -C buildroot O=output/wb40n source

source-wb45n:
	$(MAKE) -C buildroot O=output/wb45n source

source: source-wb40n source-wb45n

clean-wb40n-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb40n sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean dhd-dirclean

clean-wb45n-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb45n  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean

clean-lrd-pkg: clean-wb40n-lrd-pkg clean-wb45n-lrd-pkg

clean-wb40n:
	$(MAKE) -C buildroot O=output/wb40n clean

clean-wb45n:
	$(MAKE) -C buildroot O=output/wb45n clean

clean: clean-wb40n clean-wb45n

cleanall:
	rm -f unpack.stamp
	cd buildroot; git clean -d -f -e "package/lrd-closed-source/externals/" \
	                              -e "package/lrd-devel/" \
	                              -e "boards/laird/customers/*" -x

legal-info-wb45n:
	$(MAKE) -C buildroot O=output/wb45n legal-info

legal-info-wb40n:
	$(MAKE) -C buildroot O=output/wb40n legal-info	

legal-info: legal-info-wb40n legal-info-wb45n

.PHONY: default all clean cleanall clean-wb40n clean-wb45n wb40n wb45n \
        source source-wb40n source-wb45n clean-lrd-pkg clean-wb40n-lrd-pkg clean-wb45n-lrd-pkg
.NOTPARALLEL:
