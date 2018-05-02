# Creates a package of required firmware and board support files for the
# Sterling series radios.

$(error firmware building on this branch is deprecated.)

ST_OUT := $(PWD)/buildroot/output/sterling

LAIRD_RELEASE_STRING ?= $(shell date +%Y%m%d)

ST_FCC_NAME := laird-sterling-fcc-$(LAIRD_RELEASE_STRING)
ST_ETSI_NAME := laird-sterling-etsi-$(LAIRD_RELEASE_STRING)

ST_FCC_OUT := $(ST_OUT)/$(ST_FCC_NAME)
ST_ETSI_OUT := $(ST_OUT)/$(ST_ETSI_NAME)

ST_BRCM_DIR := $(PWD)/buildroot/package/lrd-closed-source/externals/firmware/brcm

ST_IMAGE_DIR := images/sterling

all: sterling-fcc sterling-etsi

#############################################################################
# Support targets
$(ST_OUT):
	mkdir -p $(ST_OUT)

#############################################################################
# Image export
$(ST_IMAGE_DIR):
	mkdir -p $(ST_IMAGE_DIR)

# $(@F) is the file part of the target
images/sterling/$(ST_FCC_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT) ; tar -cjf $(@F) $(ST_FCC_NAME)
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(ST_ETSI_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT) ; tar -cjf $(@F) $(ST_ETSI_NAME)
	cp $(ST_OUT)/$(@F) $@

sterling-fcc-staging: $(ST_OUT)
	mkdir -p $(ST_FCC_OUT)
	cp $(ST_BRCM_DIR)/bcmdhd_4343w_fcc-*.cal $(ST_FCC_OUT)
	cp $(ST_BRCM_DIR)/fw_bcmdhd_4343w-*.bin $(ST_FCC_OUT)
	cp $(ST_BRCM_DIR)/fw_bcmdhd_mfgtest_4343w-*.bin $(ST_FCC_OUT)
	cp $(ST_BRCM_DIR)/4343w-*.hcd $(ST_FCC_OUT)
	cd $(ST_FCC_OUT);\
	ln -sf bcmdhd_4343w_fcc-*.cal brcmfmac43430-sdio.txt;\
	ln -sf fw_bcmdhd_4343w-*.bin brcmfmac43430-sdio.bin

sterling-etsi-staging: $(ST_OUT)
	mkdir -p $(ST_ETSI_OUT)
	cp $(ST_BRCM_DIR)/bcmdhd_4343w_etsi-*.cal $(ST_ETSI_OUT)
	cp $(ST_BRCM_DIR)/fw_bcmdhd_4343w-*.bin $(ST_ETSI_OUT)
	cp $(ST_BRCM_DIR)/fw_bcmdhd_mfgtest_4343w-*.bin $(ST_ETSI_OUT)
	cp $(ST_BRCM_DIR)/4343w-*.hcd $(ST_ETSI_OUT)
	cd $(ST_ETSI_OUT);\
	ln -sf bcmdhd_4343w_etsi-*.cal brcmfmac43430-sdio.txt;\
	ln -sf fw_bcmdhd_4343w-*.bin brcmfmac43430-sdio.bin

#############################################################################
#  clean targets
clean-all:
	rm -rf $(ST_OUT)
	rm -f images/sterling/$(ST_FCC_NAME).tar.bz2
	rm -f images/sterling/$(ST_ETSI_NAME).tar.bz2

clean:
	rm -rf $(ST_FCC_OUT)
	rm -rf $(ST_ETSI_OUT)
	rm -f $(ST_OUT)/$(ST_FCC_NAME).tar.bz2
	rm -r $(ST_OUT)/$(ST_ETSI_NAME).tar.bz2
	rm -f images/sterling/$(ST_FCC_NAME).tar.bz2
	rm -f images/sterling/$(ST_ETSI_NAME).tar.bz2


clean-nuke:
	rm -rf $(ST_OUT)
	rm -rf images/sterling

#############################################################################
# top level targets

sterling-fcc: sterling-fcc-staging images/sterling/$(ST_FCC_NAME).tar.bz2

sterling-etsi: sterling-etsi-staging images/sterling/$(ST_ETSI_NAME).tar.bz2

.PHONY: all sterling-fcc sterling-etsi clean clean-all clean-nuke
