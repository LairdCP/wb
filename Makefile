include laird_version.mk

# if BR2_DL_DIR is set, archives are downloaded to BR2_DL_DIR
ifdef BR2_DL_DIR
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.10.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/msd50n-laird-$(MSD_VERSION).tar.bz2 \
                           archive/backports-laird-$(MSD_VERSION).tar.bz2 \
                           archive/480-0108-$(MSD_VERSION).zip \
                           archive/480-0109-$(MSD_VERSION).zip \
                           archive/laird-60-radio-firmware-$(MSD_VERSION).tar.bz2 \
                           archive/summit_supplicant-arm-$(MSD_VERSION).tar.bz2
endif

# Developers should not export LAIRD_RELEASE_STRING, only Jenkins should
# 0.0.0.0 indicates that the build is for development purposes only
ifndef LAIRD_RELEASE_STRING
export LAIRD_RELEASE_STRING = 0.0.0.0
endif

default: wb50n_legacy

all: msd-x86 msd50n wb50n_legacy som60 bdimx6 backports firmware linux-docs

msd50n_config msd-x86_config wb50n_rdvk_config reg50n_config reglwb_config reglwb5_config mfg60n_config mfg60n-x86_config wb50n_legacy_config som60_config som60sd_config som60sd_mfg_config bdimx6_config sterling_supplicant-x86_config sterling_supplicant-arm_config backports_config firmware_config summit_supplicant-arm_config summit_supplicant-x86_config: unpack.stamp
    # install the config file
    # $(subst _config,,$@) trims the _config part so we get clean directory and target
	$(MAKE) O=output/$(subst _config,,$@) -C buildroot $(subst _config,,$@)_defconfig
	# mark the operation as done.
	touch $@

msd-x86 msd50n wb50n_rdvk reg50n reglwb reglwb5 mfg60n mfg60n-x86 som60sd_mfg backports firmware sterling_supplicant-x86 sterling_supplicant-arm summit_supplicant-arm summit_supplicant-x86: unpack.stamp
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

linux-docs:
	$(MAKE) -C images $@; \
	if [ $$? -ne 0 ]; \
	then \
		echo "ERROR: linux-docs build failed"; \
		echo "INFO: have you run \"sudo ./linux_docs/setup-latex.sh\""; \
		false; \
	fi

# NOTE, summit_supplicant is *NOT* released as source

lrd-network-manager-src:
	$(MAKE) -C images $@

som60 som60sd:unpack.stamp
ifeq (,$(wildcard $(BR2_DL_DIR)/summit_supplicant-arm-$(MSD_VERSION).tar.bz2))
	$(MAKE) summit_supplicant-arm
endif
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
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
ifeq (,$(wildcard $(BR2_DL_DIR)/laird-60-radio-firmware-$(MSD_VERSION).tar.bz2))
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

clean-wb50n_legacy clean-msd50n clean-wb50n_rdvk clean-msd-x86 clean-reg50n clean-reglwb clean-reglwb5 clean-mfg60n clean-mfg60n-x86 clean-som60 clean-som60sd clean-som60sd_mfg clean-bdimx6 clean-backports clean-firmware clean-sterling_supplicant-x86 clean-sterling_supplicant-arm clean-summit_supplicant-arm clean-summit_supplicant-x86:
	$(MAKE) -C buildroot O=output/$(subst clean-,,$@) clean
	rm -f $(subst clean-,,$@)_config

clean: clean-msd50n clean-msd-x86 clean-sterling_supplicant-x86 clean-sterling_supplicant-arm clean-backports clean-firmware \
	clean-reg50n clean-reglwb clean-reglwb5 clean-mfg60n clean-mfg60n-x86 clean-wb50n_legacy clean-bdimx6 clean-som60 clean-som60sd clean-som60sd_mfg

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

.PHONY: default all clean cleanall msd50n wb50n_rdvk reg50n linux-docs\
	reglwb reglwb5 mfg60n mfg60n-x86 bdimx6 msd-x86 clean-msd50n \
	clean-msd-x86 clean-wb50n_rdvk clean-reg50n clean-reglwb clean-reglwb5 \
	clean-mfg60n clean-mfg60n-x86 clean-wb50n_legacy prune-workspace clean-bdimx6 clean-firmware\
	som60 clean-som60 som60sd clean-som60sd som60sd_mfg clean-som60sd_mfg bdimx6 backports

.PHONY: sterling_supplicant-x86 clean-sterling_supplicant-x86
.PHONY: sterling_supplicant-arm clean-sterling_supplicant-arm
.PHONY: sterling_supplicant-src
.PHONY: summit_supplicant-x86 clean-summit_supplicant-x86
.PHONY: summit_supplicant-arm clean-summit_supplicant-arm

.NOTPARALLEL:
