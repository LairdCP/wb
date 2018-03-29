include laird_version.mk
# This makefile downloads buildroot from the buildroot website
# and prepares it for Laird WB40/45 building

# if BR2_DL_DIR is set, archives are downloaded to BR2_DL_DIR
ifdef BR2_DL_DIR
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.10.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/msd50n-laird-$(MSD_VERSION).tar.bz2 \
                           archive/msd45n-laird-$(MSD_VERSION).tar.bz2
endif

# Developers should not export LAIRD_RELEASE_STRING, only Jenkins should
# 0.0.0.0 indicates that the build is for development purposes only
ifndef LAIRD_RELEASE_STRING
export LAIRD_RELEASE_STRING = 0.0.0.0
endif

default: wb45n_legacy wb50n_legacy

all: wb45n_legacy msd45n msd-x86 msd50n wb50n_legacy som60 bdimx6

msd45n_config msd50n_config msd-x86_config wb50n_rdvk_config reg45n_config reg50n_config reglwb_config reglwb5_config mfg60n_config wb45n_legacy_config wb50n_legacy_config som60_config bdimx6_config sterling_supplicant-x86_config sterling_supplicant-arm_config: unpack.stamp
    # install the config file
    # $(subst _config,,$@) trims the _config part so we get clean directory and target
	$(MAKE) O=output/$(subst _config,,$@) -C buildroot $(subst _config,,$@)_defconfig
	# mark the operation as done.
	touch $@

msd45n msd-x86 msd50n wb50n_rdvk reg45n reg50n reglwb reglwb5 mfg60n wb45n_legacy wb50n_legacy som60 bdimx6 sterling_supplicant-x86 sterling_supplicant-arm: unpack.stamp
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

wb45n_legacy: unpack.stamp
ifeq (,$(wildcard $(BR2_DL_DIR)/msd45n-laird-$(LAIRD_RELEASE_STRING).tar.bz2))
	$(MAKE) msd45n
endif
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

wb50n_legacy: unpack.stamp
ifeq (,$(wildcard $(BR2_DL_DIR)/msd50n-laird-$(LAIRD_RELEASE_STRING).tar.bz2))
	$(MAKE) msd50n
endif
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

# targets that do not require the buildroot step
sterling_supplicant-src:
	$(MAKE) -C images $@

lrd-network-manager-src:
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

source-som60:
	$(MAKE) -C buildroot O=output/som60 source


source-bdimx6:
	$(MAKE) -C buildroot O=output/bdimx6 source

source-wb45n_legacy:
	$(MAKE) -C buildroot O=output/wb45n_legacy source

source-wb50n_legacy:
	$(MAKE) -C buildroot O=output/wb50n_legacy source

source: source-wb45n_legacy

clean-wb45n_legacy:
	$(MAKE) -C buildroot O=output/wb45n_legacy clean
	rm -f wb45n_legacy_config

clean-wb50n_legacy:
	$(MAKE) -C buildroot O=output/wb50n_legacy clean
	rm -f wb50n_legacy_config

clean-som60:
	$(MAKE) -C buildroot O=output/som60 clean
	rm -f som60_config

clean-msd45n:
	$(MAKE) -C buildroot O=output/msd45n clean
	rm -f msd45n_config
	rm -f $(BR2_DL_DIR)/msd45n-laird-$(LAIRD_RELEASE_STRING).tar.bz2

clean-msd50n:
	$(MAKE) -C buildroot O=output/msd50n clean
	rm -f msd50n_config
	rm -f $(BR2_DL_DIR)/msd50n-laird-$(LAIRD_RELEASE_STRING).tar.bz2

clean-wb50n_rdvk:
	$(MAKE) -C buildroot O=output/wb50n_rdvk clean
	rm -f wb50n_rdvk_config

clean-msd-x86:
	$(MAKE) -C buildroot O=output/msd-x86 clean
	rm -f msd-x86_config

clean-reg45n:
	$(MAKE) -C buildroot O=output/reg45n clean
	rm -f reg45n_config

clean-reg50n:
	$(MAKE) -C buildroot O=output/reg50n clean
	rm -f reg50n_config

clean-reglwb:
	$(MAKE) -C buildroot O=output/reglwb clean
	rm -f reglwb_config

clean-reglwb5:
	$(MAKE) -C buildroot O=output/reglwb5 clean
	rm -f reglwb5_config

clean-mfg60n:
	$(MAKE) -C buildroot O=output/mfg60n clean
	rm -f mfg60n_config

clean-bdimx6:
	$(MAKE) -C buildroot O=output/bdimx6 clean
	rm -f bdimx6_config

clean-sterling_supplicant-x86 clean-sterling_supplicant-arm:
	$(MAKE) -C buildroot O=output/$(subst clean-,,$@) clean
	rm -f $(subst clean-,,$@)_config

clean:  clean-msd45n clean-msd50n clean-msd-x86 \
	clean-sterling_supplicant-x86 clean-sterling_supplicant-arm \
	clean-reg45n clean-reg50n clean-reglwb clean-reglwb5 clean-mfg60n clean-wb45n_legacy clean-wb50n_legacy clean-bdimx6 clean-som60

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

legal-info-wb45n_legacy: wb45n_legacy_config
	$(MAKE) -C buildroot O=output/wb45n_legacy legal-info
	$(MAKE) -C images $@

legal-info-wb50n_legacy: wb50n_legacy_config
	$(MAKE) -C buildroot O=output/wb50n_legacy legal-info
	$(MAKE) -C images $@

legal-info-som60: som60_config
	$(MAKE) -C buildroot O=output/som60 legal-info
	$(MAKE) -C images $@

legal-info-bdimx6: bdimx6_config
	$(MAKE) -C buildroot O=output/bdimx6 legal-info
	$(MAKE) -C images $@

legal-info: legal-info-wb45n_legacy legal-info-wb50n_legacy legal-info-som60 legal-info-bdimx6

.PHONY: default all clean cleanall source-wb45n_legacy msd50n wb50n_rdvk reg45n reg50n \
	reglwb reglwb5 mfg60n source-wb50n_legacy msd-x86 clean-msd45n clean-msd50n \
	clean-msd-x86 clean-wb50n_rdvk clean-reg45n clean-reg50n clean-reglwb clean-reglwb5 \
	clean-mfg60n clean-wb45n_legacy clean-wb50n_legacy prune-workspace \
	som60 source-som60 clean-som60 legal-info-som60 clean-bdimx6 bdimx6 legal-info-bdimx6 source-bdimx6

.PHONY: sterling_supplicant-x86 clean-sterling_supplicant-x86
.PHONY: sterling_supplicant-arm clean-sterling_supplicant-arm
.PHONY: sterling_supplicant-src

.NOTPARALLEL:
