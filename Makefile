include laird_version.mk
# This makefile downloads buildroot from the buildroot website
# and prepares it for Laird WB40/45 building

# if BR2_DL_DIR is set, archives are downloaded to BR2_DL_DIR
ifdef BR2_DL_DIR
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.10.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/msd50n-laird-$(MSD_VERSION).tar.bz2 \
                           archive/msd45n-laird-$(MSD_VERSION).tar.bz2 \
                           archive/backports-laird-$(MSD_VERSION).tar.bz2 \
                           archive/480-0108-$(MSD_VERSION).zip\
                           archive/480-0109-$(MSD_VERSION).zip\
                           archive/laird-sterling-60-$(MSD_VERSION).tar.bz2
endif

default: wb45n_legacy wb50n_legacy

all: wb45n_legacy msd45n msd-x86 msd50n wb50n_legacy bdimx6 backports firmware

msd45n_config msd50n_config msd-x86_config wb50n_rdvk_config reg45n_config reg50n_config reglwb_config reglwb5_config mfg60n_config mfg60n-x86_config wb45n_legacy_config wb50n_legacy_config bdimx6_config sterling_supplicant-x86_config sterling_supplicant-arm_config backports_config firmware_config: unpack.stamp
    # install the config file
    # $(subst _config,,$@) trims the _config part so we get clean directory and target
	$(MAKE) O=output/$(subst _config,,$@) -C buildroot $(subst _config,,$@)_defconfig
	# mark the operation as done.
	touch $@

msd45n msd-x86 msd50n wb50n_rdvk reg45n reg50n reglwb reglwb5 mfg60n mfg60n-x86 wb45n_legacy wb50n_legacy backports firmware sterling_supplicant-x86 sterling_supplicant-arm: unpack.stamp
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) -C images $@

# targets that do not require the buildroot step
sterling_supplicant-src:
	$(MAKE) -C images $@

lrd-network-manager-src:
	$(MAKE) -C images $@

bdimx6: unpack.stamp
ifeq (,$(wildcard $(BR2_DL_DIR)/backports-laird-$(MSD_VERSION).tar.bz2))
	$(MAKE) backports
endif
ifeq (,$(wildcard $(BR2_DL_DIR)/laird-lwb-firmware-mfg-$(MSD_VERSION).tar.bz2))
	$(MAKE) firmware
endif
ifeq (,$(wildcard $(BR2_DL_DIR)/laird-lwb5-firmware-mfg-$(MSD_VERSION).tar.bz2))
	$(MAKE) firmware
endif
ifeq (,$(wildcard $(BR2_DL_DIR)/laird-sterling-60-$(MSD_VERSION).tar.bz2))
	$(MAKE) firmware
endif
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

clean-wb45n_legacy clean-wb50n_legacy clean-msd45n clean-msd50n clean-wb50n_rdvk clean-msd-x86 clean-reg45n clean-reg50n clean-reglwb clean-reglwb5 clean-mfg60n clean-mfg60n-x86 clean-bdimx6 clean-backports clean-firmware clean-sterling_supplicant-x86 clean-sterling_supplicant-arm:
	$(MAKE) -C buildroot O=output/$(subst clean-,,$@) clean
	rm -f $(subst clean-,,$@)_config

clean:  clean-msd45n clean-msd50n clean-msd-x86 clean-firmware\
	clean-sterling_supplicant-x86 clean-sterling_supplicant-arm clean-backports\
	clean-reg45n clean-reg50n clean-reglwb clean-reglwb5 clean-mfg60n clean-mfg60n-x86 clean-wb45n_legacy clean-wb50n_legacy


cleanall:
	rm -f unpack.stamp
	rm -f *_config
	cd buildroot; rm output/ -fr; git clean -df

# The prune-workspace target is intended for CI systems to cleanup after a
# successful build. It isn't intended for users to use.
prune-workspace:
	rm -rf buildroot
	rm -rf ../.repo/projects
	rm -rf ../.repo/projects-objects
	rm -rf ../wb_docs
	rm -rf archive examples doc
	rm -rf .git

.PHONY: default all clean cleanall source-wb45n_legacy msd50n wb50n_rdvk reg45n reg50n \
	reglwb reglwb5 mfg60n mfg60n-x86 bdimx6 source-wb50n_legacy msd-x86 backports clean-msd45n clean-msd50n \
	clean-msd-x86 clean-wb50n_rdvk clean-reg45n clean-reg50n clean-reglwb clean-reglwb5 clean-firmware \
	clean-mfg60n clean-mfg60n-x86 clean-wb45n_legacy clean-wb50n_legacy clean-bdimx6 clean-backports prune-workspace

.PHONY: sterling_supplicant-x86 clean-sterling_supplicant-x86
.PHONY: sterling_supplicant-arm clean-sterling_supplicant-arm
.PHONY: sterling_supplicant-src

.NOTPARALLEL:
