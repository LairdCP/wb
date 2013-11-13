# This makefile downloads buildroot from the buildroot website
# and prepares it for Laird WB40/45 building

# if BUILDROOT_DL_DIR is set, archives are downloaded to BUILDROOT_DL_DIR
LAIRD_DL_DIR := archive
ifdef BUILDROOT_DL_DIR
LAIRD_DL_DIR            := $(BUILDROOT_DL_DIR)
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.5.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/msd45n-laird_fips-3.4.1.3.tar.bz2 \
                           archive/msd40n-laird-3.4.1.3.tar.bz2
endif

URL   := http://buildroot.uclibc.org/downloads/
VER   := 2013.02
PKG   := buildroot-$(VER)
ARCHV := $(PKG).tar.bz2

default: wb40n wb45n

all: wb40n wb45n msd40n msd45n welch_allyn carefusion

msd40n msd45n msd45n_fips welch_allyn carefusion wb40n wb45n wb45n_devel wb40n_devel: unpack.stamp
	# install the config file
	$(MAKE) O=output/$@ -C buildroot $@_defconfig
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

unpack: unpack.stamp
unpack.stamp: $(LAIRD_DL_DIR)/$(ARCHV)
ifdef BUILDROOT_DL_DIR
	# copy the Laird archives into the override buildroot directory
	cp -n $(LAIRD_ARCHIVES) $(BUILDROOT_DL_DIR)/
	for i in $(LAIRD_ARCHIVES_OPTIONAL); do \
	    test -f $$i && cp -n $$i $(BUILDROOT_DL_DIR)/ || true; \
	done
endif
	# unpack buildroot, rename the directory to 'buildroot' for easier management
	tar xf $(LAIRD_DL_DIR)/$(ARCHV) --xform "s/^$(PKG)/buildroot/"
	patch -d buildroot -p1 < buildroot-patches/buildroot-2013.02-laird1.patch
	patch -d buildroot -p1 < buildroot-patches/wireless-regdb.patch
	patch -d buildroot -p1 < buildroot-patches/crda.patch
	patch -d buildroot -p1 < buildroot-patches/strip_whitespace_device_table.patch
	patch -d buildroot -p1 -R < buildroot-patches/external-toolchain-relocatable.patch
	# link the board configs as *_defconfig names
	cd buildroot/configs && ln -s ../board/sdc/customers/welch_allyn/configs/buildroot.config welch_allyn_defconfig
	cd buildroot/configs && ln -s ../board/sdc/customers/carefusion/configs/buildroot.config carefusion_defconfig
	cd buildroot/configs && ln -s ../board/sdc/wb40n/configs/buildroot.config wb40n_defconfig
	cd buildroot/configs && ln -s ../board/sdc/wb40n/configs/buildroot-wb40n_devel.config wb40n_devel_defconfig
	cd buildroot/configs && ln -s ../board/sdc/wb45n/configs/buildroot.config wb45n_defconfig
	cd buildroot/configs && ln -s ../board/sdc/wb45n/configs/buildroot-wb45n_devel.config wb45n_devel_defconfig
	cd buildroot/configs && ln -s ../board/sdc/msd40n/configs/buildroot.config msd40n_defconfig
	cd buildroot/configs && ln -s ../board/sdc/msd45n/configs/buildroot.config msd45n_defconfig
	cd buildroot/configs && ln -s ../board/sdc/msd45n/configs/buildroot-fips.config msd45n_fips_defconfig
	# mark operation as done
	touch unpack.stamp

$(LAIRD_DL_DIR)/$(ARCHV):
	wget -nc -c $(URL)$(ARCHV) -O $@

source-wb40n:
	$(MAKE) -C buildroot O=output/wb40n source

source-wb45n:
	$(MAKE) -C buildroot O=output/wb45n source

source: source-wb40n source-wb45n

clean-wb40n-sdc-pkg:
	$(MAKE) -C buildroot O=output/wb40n sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean dhd-dirclean

clean-wb45n-sdc-pkg:
	$(MAKE) -C buildroot O=output/wb45n  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean

clean-sdc-pkg: clean-wb40n-sdc-pkg clean-wb45n-sdc-pkg

clean-wb40n:
	$(MAKE) -C buildroot O=output/wb40n clean

clean-wb45n:
	$(MAKE) -C buildroot O=output/wb45n clean

clean: clean-wb40n clean-wb45n

cleanall:
	find buildroot/ -mindepth 1 -maxdepth 1 -not -name board -not -name package -not -name laird-devel \
                    -not -name '.svn' -not -name '.git' \
                    -exec rm -rf "{}" ";"
	find buildroot/package buildroot/board  -mindepth 1 -maxdepth 1 \
                -not -name sdc -not -name sdc-closed-source -not -name sdc-devel \
                -not -name ncm \
		-not -name '.svn' -not -name .git \
                -exec rm -rf "{}" ";"
	rm -f unpack.stamp
	
legal-info-wb45n:
	$(MAKE) -C buildroot O=output/wb45n legal-info

legal-info-wb40n:
	$(MAKE) -C buildroot O=output/wb40n legal-info	

legal-info: legal-info-wb40n legal-info-wb45n
	
.PHONY: default all unpack clean cleanall clean-wb40n clean-wb45n wb40n wb45n \
        source source-wb40n source-wb45n clean-sdc-pkg clean-wb40n-sdc-pkg clean-wb45n-sdc-pkg welch_allyn carefusion
.NOTPARALLEL:
