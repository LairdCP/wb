# Developers should not export LAIRD_RELEASE_STRING, only Jenkins should
# 0.0.0.0 indicates that the build is for development purposes only
export LAIRD_RELEASE_STRING ?= 0.0.0.0

TARGETS = bdimx6 \
	reg50n reg50n-arm-eabihf \
	wb50n_rdvk wb50n_sysd wb50nsd_sysd wb50n_legacy \
	wb50n_sysd_fips wb50nsd_sysd_fips \
	regCypress-arm-eabi regCypress-arm-eabihf regCypress-arm-eabiaarch64 \
	mfg60n-arm-eabi mfg60n-x86 mfg60n-arm-eabihf mfg60n-arm-eabiaarch64 mfg60n-powerpc-e5500\
	som60 som60sd som60sd_mfg som60x2 som60x2sd som60x2sd_mfg \
	ig60 ig60llsd ig60sd-wbx3 wb60 wb60sd \
	som60_fips som60sd_fips \
	backports firmware \
	sterling_supplicant-x86 sterling_supplicant-arm \
	summit_supplicant-x86 summit_supplicant-arm-eabi summit_supplicant-arm-eabihf \
	summit_supplicant-aarch64-eabihf summit_supplicant_openssl_1_0_2-arm-eabihf \
	summit_supplicant_openssl_1_0_2-aarch64-eabihf summit_supplicant_openssl_1_0_2-arm-eabi \
	summit_supplicant_openssl_1_0_2-x86 summit_supplicant_fips-arm-eabihf \
	summit_supplicant_legacy-arm-eabi \
	laird_openssl_fips-arm-eabihf \
	adaptive_ww-arm-eabi adaptive_ww-arm-eabihf adaptive_ww-x86 adaptive_ww-arm-eabiaarch64 adaptive_ww-powerpc-e5500 \
	adaptive_ww_openssl_1_0_2-arm-eabi adaptive_ww_openssl_1_0_2-arm-eabihf adaptive_ww_openssl_1_0_2-x86 \
	adaptive_ww_openssl_1_0_2-arm-eabiaarch64 adaptive_ww_openssl_1_0_2-powerpc-e5500

# NOTE, summit_supplicant is *NOT* released as source
TARGETS_SRC = sterling_supplicant-src lrd-network-manager-src
TARGETS_TEST = backports-test

TARGETS_CONFIG = $(addsuffix _config, $(TARGETS) $(TARGETS_TEST))
TARGETS_CLEAN  = $(addprefix clean-,  $(TARGETS) $(TARGETS_TEST))

default: wb50n_legacy

all: msd-x86 msd50n wb50n_legacy som60 bdimx6 backports firmware linux-docs

$(TARGETS_CONFIG):
    # install the config file
    # $(subst _config,,$@) trims the _config part so we get clean directory and target
	$(MAKE) O=output/$(subst _config,,$@) -C buildroot $(subst _config,,$@)_defconfig
	# mark the operation as done.
	touch $@

$(TARGETS):
	# first check/do config, because can't use $@ in dependency
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot
	$(MAKE) O=output/$@ sbom-gen -C buildroot
	$(MAKE) -C images $@

# targets that do not require images
$(TARGETS_TEST):
	$(MAKE) $@_config
	$(MAKE) O=output/$@ -C buildroot

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

$(TARGETS_CLEAN):
	$(MAKE) -C buildroot O=output/$(subst clean-,,$@) distclean
	rm -f $(subst clean-,,$@)_config

clean: $(TARGETS_CLEAN)

cleanall:
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
.PHONY: $(TARGETS) $(TARGETS_SRC) $(TARGETS_TEST) $(TARGETS_CLEAN)

.NOTPARALLEL:
