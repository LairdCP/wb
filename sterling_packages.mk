# Creates a package of required firmware and board support files for the
# Sterling series radios.

ST_OUT := $(PWD)/buildroot/output/sterling

LAIRD_RELEASE_STRING ?= $(shell date +%Y%m%d)

LWB_FCC_NAME := laird-sterling-fcc-$(LAIRD_RELEASE_STRING)
LWB_ETSI_NAME := laird-sterling-etsi-$(LAIRD_RELEASE_STRING)
LWB5_FCC_NAME := laird-lwb5-fcc-$(LAIRD_RELEASE_STRING)

LWB_FCC_OUT := $(ST_OUT)/$(LWB_FCC_NAME)
LWB_ETSI_OUT := $(ST_OUT)/$(LWB_ETSI_NAME)
LWB5_FCC_OUT := $(ST_OUT)/$(LWB5_FCC_NAME)

ST_BRCM_DIR := $(PWD)/buildroot/package/lrd-closed-source/externals/firmware/brcm

ST_IMAGE_DIR := images/sterling

all: lwb-fcc lwb-etsi lwb5-fcc

#############################################################################
# Support targets
$(ST_OUT):
	mkdir -p $(ST_OUT)

#############################################################################
# Image export
$(ST_IMAGE_DIR):
	mkdir -p $(ST_IMAGE_DIR)

# $(@F) is the file part of the target
images/sterling/$(LWB_FCC_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT) ; tar -cjf $(@F) $(LWB_FCC_NAME)
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(LWB_ETSI_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT) ; tar -cjf $(@F) $(LWB_ETSI_NAME)
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(LWB5_FCC_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(LWB5_FCC_OUT) ; tar -cjf $(ST_OUT)/$(@F) .
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip: images/sterling/$(LWB5_FCC_NAME).tar.bz2
	cd $(ST_OUT) ; zip $(@F) $(LWB5_FCC_NAME).tar.bz2
	cp $(ST_OUT)/$(@F) $@

lwb-fcc-staging: $(ST_OUT)
	mkdir -p $(LWB_FCC_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-11-15/bcmdhd_4343w_fcc-*.cal $(LWB_FCC_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-11-15/fw_bcmdhd_4343w-*.bin $(LWB_FCC_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-11-15/fw_bcmdhd_mfgtest_4343w-*.bin $(LWB_FCC_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-07-25/4343w-*.hcd $(LWB_FCC_OUT)
	cd $(LWB_FCC_OUT);\
	ln -sf bcmdhd_4343w_fcc-*.cal brcmfmac43430-sdio.txt;\
	ln -sf fw_bcmdhd_4343w-*.bin brcmfmac43430-sdio.bin

lwb-etsi-staging: $(ST_OUT)
	mkdir -p $(LWB_ETSI_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-11-15/bcmdhd_4343w_etsi-*.cal $(LWB_ETSI_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-11-15/fw_bcmdhd_4343w-*.bin $(LWB_ETSI_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-11-15/fw_bcmdhd_mfgtest_4343w-*.bin $(LWB_ETSI_OUT)
	cp $(ST_BRCM_DIR)/bcm4343w/2016-07-25/4343w-*.hcd $(LWB_ETSI_OUT)
	cd $(LWB_ETSI_OUT);\
	ln -sf bcmdhd_4343w_etsi-*.cal brcmfmac43430-sdio.txt;\
	ln -sf fw_bcmdhd_4343w-*.bin brcmfmac43430-sdio.bin

lwb5-fcc-staging: $(ST_OUT)
	mkdir -p $(LWB5_FCC_OUT)/lib/firmware/brcm/bcm4339/region-fcc
	cp -rad $(ST_BRCM_DIR)/bcm4339/* $(LWB5_FCC_OUT)/lib/firmware/brcm/bcm4339/region-fcc
	echo $(LAIRD_RELEASE_STRING) > $(LWB5_FCC_OUT)/lib/firmware/brcm/bcm4339/region-fcc/laird-release
	cd $(LWB5_FCC_OUT)/lib/firmware/brcm/bcm4339;\
        ln -sf ./region-fcc ./region ;\
	ln -sf ./region/4339.hcd . ;\
	ln -sf ./region/brcmfmac4339-sdio.txt . ;\
	ln -sf ./region/brcmfmac4339-sdio.bin .
	cd $(LWB5_FCC_OUT)/lib/firmware/brcm;\
	ln -sf ./bcm4339/4339.hcd . ;\
	ln -sf ./bcm4339/brcmfmac4339-sdio.txt . ;\
	ln -sf ./bcm4339/brcmfmac4339-sdio.bin .

#############################################################################
#  clean targets
clean-all:
	rm -rf $(ST_OUT)
	rm -f images/sterling/$(LWB_FCC_NAME).tar.bz2
	rm -f images/sterling/$(LWB_ETSI_NAME).tar.bz2
	rm -f images/sterling/$(LWB5_FCC_NAME).tar.bz2
	rm -f images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip

clean:
	rm -rf $(LWB_FCC_OUT)
	rm -rf $(LWB_ETSI_OUT)
	rm -f $(ST_OUT)/$(LWB_FCC_NAME).tar.bz2
	rm -r $(ST_OUT)/$(LWB_ETSI_NAME).tar.bz2
	rm -r $(ST_OUT)/480-0081-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/$(LWB_FCC_NAME).tar.bz2
	rm -f images/sterling/$(LWB_ETSI_NAME).tar.bz2
	rm -f images/sterling/$(LWB5_FCC_NAME).tar.bz2
	rm -f images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip

clean-nuke:
	rm -rf $(ST_OUT)
	rm -rf images/sterling

#############################################################################
# top level targets

lwb-fcc: lwb-fcc-staging images/sterling/$(LWB_FCC_NAME).tar.bz2

lwb-etsi: lwb-etsi-staging images/sterling/$(LWB_ETSI_NAME).tar.bz2

lwb5-fcc: lwb5-fcc-staging images/sterling/$(LWB5_FCC_NAME).tar.bz2 images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip


.PHONY: all lwb-fcc lwb-etsi lwb5-fcc clean clean-all clean-nuke
