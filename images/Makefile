TARGETS = $(patsubst %/Makefile,%,$(wildcard */Makefile))

force:

$(TARGETS): force
	$(MAKE) -C $@ all

define BUILD_template
	mkdir -p $@
	$(MAKE) -f ../common.mk -C $@ all PRODUCT=$@ BULID_TYPE=$(1)
endef

#make does not allow to mix pattern and non-pattern rules, so seprate them
summit_supplicant% sterling_supplicant% mfg60n% reg% adaptive_ww% laird_openssl_fips%: force
	$(call BUILD_template,pkg)

backports firmware: force
	$(call BUILD_template,pkg)

wb50n_legacy wb50n_rdvk: force
	$(call BUILD_template,legacy)

som60sd som60sd_fips som60sd_mfg som60x2sd som60x2sd_mfg wb60sd wb50nsd_sysd wb50nsd_sysd_fips ig60llsd ig60sd-wbx3: force
	$(call BUILD_template,sd60)

som60 som60_fips som60x2 wb60 wb50n_sysd wb50n_sysd_fips: force
	$(call BUILD_template,nand60)

ig60: force
	$(call BUILD_template,nand60-secure)

bdimx6: force
	mkdir -p $@
	$(MAKE) -f ../common.mk -C $@ all PRODUCT=$@ EXTRA_FILES=sdcard.img
