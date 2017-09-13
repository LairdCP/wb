# This makefile downloads buildroot from the buildroot website
# and prepares it for Laird WB40/45 building

# if BR2_DL_DIR is set, archives are downloaded to BR2_DL_DIR
ifdef BR2_DL_DIR
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.10.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/msd50n-laird-3.5.4.13.tar.bz2 \
			   archive/msd45n-laird-3.5.4.13.tar.bz2 \
                           archive/msd40n-laird-3.5.4.13.tar.bz2
endif

default: wb45n wb50n

all: wb40n wb45n msd40n msd45n msd-x86 msd50n wb50n

msd40n_config msd45n_config msd50n_config wb40n_config wb45n_config wb45n_devel_config wb40n_devel_config msd-x86_config wb50n_config wb50n_devel_config wb50n_rdvk_config wb50n_rdvk_devel_config reg45n_config reg50n_config mfg60n_config wb45n_legacy_config wb45n_legacy_devel_config wb50n_legacy_config wb50n_legacy_devel_config: unpack.stamp
    # install the config file
    # $(subst _config,,$@) trims the _config part so we get clean directory and target
	$(MAKE) O=output/$(subst _config,,$@) -C buildroot $(subst _config,,$@)_defconfig
	# mark the operation as done.
	touch $@

msd40n msd45n wb40n wb45n wb45n_devel wb40n_devel msd-x86 msd50n wb50n_devel wb50n wb50n_rdvk wb50n_rdvk_devel reg45n reg50n mfg60n wb45n_legacy wb45n_legacy_devel wb50n_legacy wb50n_legacy_devel: unpack.stamp
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

unpack: unpack.stamp
unpack.stamp:
ifdef BR2_DL_DIR
        # copy the Laird archives into the override buildroot directory
	cp -n $(LAIRD_ARCHIVES) $(BR2_DL_DIR)/
	for i in $(LAIRD_ARCHIVES_OPTIONAL); do \
	    test -f $$i && cp -n $$i $(BR2_DL_DIR)/ || true; \
	done
endif
        # mark operation as done
	touch unpack.stamp

source-wb40n:
	$(MAKE) -C buildroot O=output/wb40n source

source-wb45n:
	$(MAKE) -C buildroot O=output/wb45n source

source-wb50n:
	$(MAKE) -C buildroot O=output/wb50n source

source: source-wb40n source-wb45n

patches-bootstrap: buildroot/package/lrd-devel/at91bootstrap3
	cd buildroot/package/lrd-devel/at91bootstrap3 &&\
	mkdir patches &&\
	git format-patch -N -o patches v3.7.1.. &&\
	cd patches/ &&\
	rename -v 's/(.*)$$/at91bootstrap3-v3.7.1-$$1/' * &&\
	cp -nv * ../../../../board/laird/wb45n/patches/at91bootstrap3-3.7.1/. &&\
	cd ../../../../..
	cd buildroot/package/lrd-devel/at91bootstrap3 &&\
	rm -rf patches &&\
	cd ../../../..

patches-uboot: buildroot/package/lrd-devel/u-boot
	cd buildroot/package/lrd-devel/u-boot &&\
	mkdir patches &&\
	git format-patch -N -o patches v2014.07.. &&\
	cd patches/ &&\
	rename -v 's/(.*)$$/u-boot-v2014.07-$$1/' * &&\
	cp -nv * ../../../../board/laird/wb45n/patches/uboot-2014.07/. &&\
	cd ../../../../..
	cd buildroot/package/lrd-devel/u-boot &&\
	rm -rf patches &&\
	cd ../../../..

patches-kernel: buildroot/package/lrd-closed-source/externals/kernel
	cd buildroot/package/lrd-closed-source/externals/kernel &&\
	mkdir patches &&\
	git format-patch -N -o patches v4.4.39.. &&\
	cd patches/ &&\
	rename -v 's/(.*)$$/linux-4.4.39-$$1/' * &&\
	cp -nv * ../../../../../board/laird/wb45n/patches/linux-4.4.39/. &&\
	cd ../../../../../..
	cd buildroot/package/lrd-closed-source/externals/kernel &&\
	rm -rf patches &&\
	cd ../../../../..

all-patches: patches-bootstrap patches-uboot patches-kernel

clean-wb40n-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb40n sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean dhd-dirclean

clean-wb45n-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb45n  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean

clean-wb40n_devel-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb40n_devel  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean dhd-dirclean

clean-wb45n_devel-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb45n_devel  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean

clean-wb50n-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb50n  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean

clean-wb50n_devel-lrd-pkg:
	$(MAKE) -C buildroot O=output/wb50n_devel  sdccli-dirclean sdcsdk-dirclean sdcsupp-dirclean

clean-lrd-pkg: clean-wb40n-lrd-pkg clean-wb40n_devel-lrd-pkg clean-wb45n-lrd-pkg clean-wb45n_devel-lrd-pkg clean-wb50n-lrd-pkg clean-wb50n_devel-lrd-pkg

clean-wb40n:
	$(MAKE) -C buildroot O=output/wb40n clean
	rm -f wb40n_config

clean-wb45n:
	$(MAKE) -C buildroot O=output/wb45n clean
	rm -f wb45n_config

clean-wb40n_devel:
	$(MAKE) -C buildroot O=output/wb40n_devel clean
	rm -f wb40n_devel_config

clean-wb45n_devel:
	$(MAKE) -C buildroot O=output/wb45n_devel clean
	rm -f wb45n_devel_config

clean-wb45n_legacy:
	$(MAKE) -C buildroot O=output/wb45n_legacy clean
	rm -f wb45n_legacy_config

clean-wb45n_legacy_devel:
	$(MAKE) -C buildroot O=output/wb45n_legacy_devel clean
	rm -f wb45n_legacy_devel_config

clean-wb50n:
	$(MAKE) -C buildroot O=output/wb50n clean
	rm -f wb50n_config

clean-wb50n_legacy:
	$(MAKE) -C buildroot O=output/wb50n_legacy clean
	rm -f wb50n_legacy_config

clean-wb50n_legacy_devel:
	$(MAKE) -C buildroot O=output/wb50n_legacy_devel clean
	rm -f wb50n_legacy_devel_config

clean-wb50n_devel:
	$(MAKE) -C buildroot O=output/wb50n_devel clean
	rm -f wb50n_devel_config

clean-msd45n:
	$(MAKE) -C buildroot O=output/msd45n clean
	rm -f msd45n_config

clean-msd50n:
	$(MAKE) -C buildroot O=output/msd50n clean
	rm -f msd50n_config

clean-wb50n_rdvk:
	$(MAKE) -C buildroot O=output/wb50n_rdvk clean
	rm -f wb50n_rdvk_config

clean-wb50n_rdvk_devel:
	$(MAKE) -C buildroot O=output/wb50n_rdvk_devel clean
	rm -f wb50n_rdvk_devel_config

clean-msd-x86:
	$(MAKE) -C buildroot O=output/msd-x86 clean
	rm -f msd-x86_config

clean-reg45n:
	$(MAKE) -C buildroot O=output/reg45n clean
	rm -f reg45n_config

clean-reg50n:
	$(MAKE) -C buildroot O=output/reg50n clean
	rm -f reg50n_config

clean-mfg60n:
	$(MAKE) -C buildroot O=output/mfg60n clean
	rm -f mfg60n_config

clean: clean-wb40n clean-wb40n_devel clean-wb45n clean-wb45n_devel clean-wb50n clean-wb50n_devel clean-msd45n clean-msd50n clean-msd-x86 \
	clean-reg45n clean-reg50n clean-mfg60n clean-wb45n_legacy clean-wb45n_legacy_devel clean-wb50n_legacy clean-wb50n_legacy_devel

cleanall:
	rm -f unpack.stamp
	rm -f *_config
	cd buildroot; git clean -d -f -e "package/lrd-closed-source/externals/" \
	                              -e "package/lrd-devel/" \
	                              -e "configs/" \
	                              -e "board/laird/customers/*" -x

# The prune-workspace target is intended for CI systems to cleanup after a
# successful build. It isn't intended for users to use.
prune-workspace:
	rm -rf buildroot
	rm -rf ../.repo/projects
	rm -rf ../.repo/projects-objects
	rm -rf ../wb_docs
	rm -rf archive examples doc
	rm -rf .git

legal-info-wb45n: wb45n_config
	$(MAKE) -C buildroot O=output/wb45n legal-info
	$(MAKE) -C images $@

legal-info-wb40n: wb40n_config
	$(MAKE) -C buildroot O=output/wb40n legal-info
	$(MAKE) -C images $@

legal-info-wb50n: wb50n_config
	$(MAKE) -C buildroot O=output/wb50n legal-info
	$(MAKE) -C images $@

legal-info: legal-info-wb40n legal-info-wb45n legal-info-wb50n

.PHONY: default all clean cleanall clean-wb40n clean-wb45n wb40n wb45n \
        source source-wb40n source-wb45n clean-lrd-pkg clean-wb40n-lrd-pkg clean-wb45n-lrd-pkg \
        clean-wb40n_devel clean-wb45n_devel clean-wb40n_devel-lrd-pkg clean-wb45n_devel-lrd-pkg \
        msd50n wb50n wb50n_devel wb50n_rdvk wb50n_rdvk_devel reg45n reg50n mfg60n source-wb50n legal-info-wb50n \
        msd-x86 clean-wb50n-lrd-pkg clean-wb50n_devel-lrd-pkg clean-wb50n clean-wb50n_devel clean-msd45n \
        clean-msd50n clean-msd-x86 clean-wb50n_rdvk clean-wb50n_rdvk_devel clean-reg45n clean-reg50n \
        clean-mfg60n clean-wb45n_legacy clean-wb45n_legacy_devel clean-wb50n_legacy clean-wb50n_legacy_devel \
        patches-bootstrap patches-uboot patches-kernel all-patches prune-workspace

.NOTPARALLEL:
