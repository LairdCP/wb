include laird_version.mk

# if BR2_DL_DIR is set, archives are downloaded to BR2_DL_DIR
ifdef BR2_DL_DIR
LAIRD_ARCHIVES          := archive/AT91Bootstrap-v3.4.4.tar.xz \
                           archive/openssl-fips-2.0.10.tar.gz
LAIRD_ARCHIVES_OPTIONAL := archive/backports-laird-$(MSD_VERSION).tar.bz2 \
                           archive/480-0108-$(MSD_VERSION).zip \
                           archive/480-0109-$(MSD_VERSION).zip \
                           archive/laird-60-radio-firmware-$(MSD_VERSION).tar.bz2 \
                           archive/summit_supplicant-arm-eabihf-$(MSD_VERSION).tar.bz2
endif

# Developers should not export LAIRD_RELEASE_STRING, only Jenkins should
# 0.0.0.0 indicates that the build is for development purposes only
ifndef LAIRD_RELEASE_STRING
export LAIRD_RELEASE_STRING = 0.0.0.0
endif

TARGETS = \
	msd-x86 msd50n reg50n \
	wb50n_rdvk wb50n_sysd wb50nsd_sysd wb50n_legacy \
	reglwb reglwb5 \
	mfg60n-arm-eabi mfg60n-x86 mfg60n-arm-eabihf mfg60n-arm-eabiaarch64 \
	som60 som60sd som60sd_mfg ig60 \
	backports firmware \
	sterling_supplicant-x86 sterling_supplicant-arm \
	summit_supplicant-x86 summit_supplicant-arm-eabi summit_supplicant-arm-eabihf

TARGETS_UNIQUE = bdimx6

# NOTE, summit_supplicant is *NOT* released as source
TARGETS_SRC = sterling_supplicant-src lrd-network-manager-src

TARGETS_CONFIG = $(addsuffix _config, $(TARGETS) $(TARGETS_UNIQUE))
TARGETS_CLEAN  = $(addprefix clean-,  $(TARGETS) $(TARGETS_UNIQUE))

default: wb50n_legacy

all: msd-x86 msd50n wb50n_legacy som60 bdimx6 backports firmware linux-docs

$(TARGETS_CONFIG): unpack.stamp
    # install the config file
    # $(subst _config,,$@) trims the _config part so we get clean directory and target
	$(MAKE) O=output/$(subst _config,,$@) -C buildroot $(subst _config,,$@)_defconfig
	# mark the operation as done.
	touch $@

$(TARGETS): unpack.stamp
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) O=output/$@ cve-check -C buildroot
	$(MAKE) -C images $@

# targets that do not require the buildroot step
$(TARGETS_SRC):
	$(MAKE) -C images $@

linux-docs:
	$(MAKE) -C images $@; \
	if [ $$? -ne 0 ]; \
	then \
		echo "ERROR: linux-docs build failed"; \
		echo "INFO: have you run \"sudo ./linux_docs/setup-latex.sh\""; \
		false; \
	fi

bdimx6: unpack.stamp
ifeq (,$(wildcard $(BR2_DL_DIR)/backports-laird-$(MSD_VERSION).tar.bz2))
	$(MAKE) backports
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

$(TARGETS_CLEAN):
	$(MAKE) -C buildroot O=output/$(subst clean-,,$@) clean
	rm -f $(subst clean-,,$@)_config

clean: $(TARGETS_CLEAN)

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

.PHONY: default all clean cleanall linux-docs
.PHONY: $(TARGETS) $(TARGETS_UNIQUE) $(TARGETS_SRC) $(TARGETS_CLEAN)

.NOTPARALLEL:
