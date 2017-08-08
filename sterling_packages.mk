# Creates a package of required firmware and board support files for the
# Sterling series radios.

ST_OUT := $(PWD)/buildroot/output/sterling

LAIRD_RELEASE_STRING ?= $(shell date +%Y%m%d)

LWB_FCC_NAME := laird-lwb-firmware-fcc-$(LAIRD_RELEASE_STRING)
LWB_ETSI_NAME := laird-lwb-firmware-etsi-$(LAIRD_RELEASE_STRING)
LWB_MFG_NAME := laird-lwb-firmware-mfg-$(LAIRD_RELEASE_STRING)

LWB5_FCC_NAME := laird-lwb5-fcc-$(LAIRD_RELEASE_STRING)
60_NAME := laird-sterling-60-$(LAIRD_RELEASE_STRING)
WL_FMAC_930_0081_NAME := 930-0081-$(LAIRD_RELEASE_STRING)

LWB_FCC_OUT := $(ST_OUT)/$(LWB_FCC_NAME)
LWB_ETSI_OUT := $(ST_OUT)/$(LWB_ETSI_NAME)
LWB_MFG_OUT := $(ST_OUT)/$(LWB_MFG_NAME)
LWB5_FCC_OUT := $(ST_OUT)/$(LWB5_FCC_NAME)
60_OUT := $(ST_OUT)/$(60_NAME)

ST_BRCM_DIR := $(PWD)/buildroot/package/lrd-closed-source/externals/firmware/brcm
ST_LRDMWL_DIR := $(PWD)/buildroot/package/lrd-closed-source/externals/firmware/lrdmwl

ST_IMAGE_DIR := images/sterling

all: lwb-fcc lwb-etsi lwb-mfg lwb5-fcc 60 wl

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
	cd $(ST_OUT)/$(LWB_FCC_NAME) ; tar -cjf ../$(@F) .
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(LWB_ETSI_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT)/$(LWB_ETSI_NAME) ; tar -cjf ../$(@F) .
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(LWB_MFG_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT)/$(LWB_MFG_NAME) ; tar -cjf ../$(@F) .
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip: images/sterling/$(LWB_MFG_NAME).tar.bz2
	cd $(ST_OUT) ; zip $(@F) $(LWB_MFG_NAME).tar.bz2
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(LWB5_FCC_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(LWB5_FCC_OUT) ; tar -cjf $(ST_OUT)/$(@F) lib
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip: images/sterling/$(LWB5_FCC_NAME).tar.bz2
	cd $(ST_OUT) ; zip $(@F) $(LWB5_FCC_NAME).tar.bz2
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(60_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(60_OUT) ; tar -cjf $(ST_OUT)/$(@F) lib
	cp $(ST_OUT)/$(@F) $@

images/sterling/$(WL_FMAC_930_0081_NAME).zip: $(ST_OUT)/$(WL_FMAC_930_0081_NAME).zip | $(ST_IMAGE_DIR)
	cp -f $^ $@

lwb-fcc-staging: $(ST_OUT)
	mkdir -p $(LWB_FCC_OUT)/lib/firmware/brcm/bcm4343w
	cd $(LWB_FCC_OUT)/lib/firmware/brcm/bcm4343w ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-prod.bin . ; \
	ln -s brcmfmac43430-sdio-prod.bin brcmfmac43430-sdio.bin ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-fcc.txt . ; \
	ln -s brcmfmac43430-sdio-fcc.txt brcmfmac43430-sdio.txt ; \
	cp $(ST_BRCM_DIR)/bcm4343w/4343w.hcd . ; \
	cd $(LWB_FCC_OUT)/lib/firmware/brcm ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.bin . ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.txt . ; \
	ln -sf ./bcm4343w/4343w.hcd .

lwb-etsi-staging: $(ST_OUT)
	mkdir -p $(LWB_ETSI_OUT)/lib/firmware/brcm/bcm4343w
	cd $(LWB_ETSI_OUT)/lib/firmware/brcm/bcm4343w ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-prod.bin . ; \
	ln -s brcmfmac43430-sdio-prod.bin brcmfmac43430-sdio.bin ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-etsi.txt . ; \
	ln -s brcmfmac43430-sdio-etsi.txt brcmfmac43430-sdio.txt ; \
	cp $(ST_BRCM_DIR)/bcm4343w/4343w.hcd .
	cd $(LWB_ETSI_OUT)/lib/firmware/brcm ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.bin . ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.txt . ; \
	ln -sf ./bcm4343w/4343w.hcd .

lwb-mfg-staging: $(ST_OUT)
	mkdir -p $(LWB_MFG_OUT)/lib/firmware/brcm/bcm4343w
	cd $(LWB_MFG_OUT)/lib/firmware/brcm/bcm4343w ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-mfg.bin . ; \
	ln -s brcmfmac43430-sdio-mfg.bin brcmfmac43430-sdio.bin ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-fcc.txt . ; \
	ln -s brcmfmac43430-sdio-fcc.txt brcmfmac43430-sdio.txt ; \
	cp $(ST_BRCM_DIR)/bcm4343w/4343w.hcd .
	cd $(LWB_MFG_OUT)/lib/firmware/brcm ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.bin . ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.txt . ; \
	ln -sf ./bcm4343w/4343w.hcd .

lwb5-fcc-staging: $(ST_OUT)
	mkdir -p $(LWB5_FCC_OUT)/lib/firmware/brcm/bcm4339/region-fcc
	cp -rd $(ST_BRCM_DIR)/bcm4339/* $(LWB5_FCC_OUT)/lib/firmware/brcm/bcm4339/region-fcc
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

60-staging: $(ST_OUT)
	mkdir -p $(60_OUT)/lib/firmware/
	cp -rd $(ST_LRDMWL_DIR) $(60_OUT)/lib/firmware/

$(ST_OUT)/$(WL_FMAC_930_0081_NAME).zip: buildroot/package/lrd-closed-source/externals/wl_fmac/bin/930-0081/wl_fmac | $(ST_OUT)
	zip --junk-paths $@ $^


#############################################################################
#  clean targets
clean-all:
	rm -rf $(ST_OUT)
	rm -f images/sterling/$(LWB_FCC_NAME).tar.bz2
	rm -f images/sterling/$(LWB_ETSI_NAME).tar.bz2
	rm -f images/sterling/$(LWB5_FCC_NAME).tar.bz2
	rm -f images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/$(60_NAME).tar.bz2

clean:
	rm -rf $(LWB_FCC_OUT)
	rm -rf $(LWB_ETSI_OUT)
	rm -rf $(LWB_MFG_OUT)
	rm -rf $(60_OUT)
	rm -f $(ST_OUT)/$(LWB_FCC_NAME).tar.bz2
	rm -f $(ST_OUT)/$(LWB_ETSI_NAME).tar.bz2
	rm -f $(ST_OUT)/$(LWB_MFG_NAME).tar.bz2
	rm -f $(ST_OUT)/480-0081-$(LAIRD_RELEASE_STRING).zip
	rm -f $(ST_OUT)/480-0108-$(LAIRD_RELEASE_STRING).zip
	rm -f $(ST_OUT)/$(WL_FMAC_930_0081_NAME).zip
	rm -f images/sterling/$(LWB_FCC_NAME).tar.bz2
	rm -f images/sterling/$(LWB_ETSI_NAME).tar.bz2
	rm -f images/sterling/$(LWB_MFG_NAME).tar.bz2
	rm -f images/sterling/$(LWB5_FCC_NAME).tar.bz2
	rm -f images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/$(WL_FMAC_930_0081_NAME).zip
	rm -f images/sterling/$(60_NAME).tar.bz2

clean-nuke:
	rm -rf $(ST_OUT)
	rm -rf images/sterling

#############################################################################
# top level targets

lwb-fcc: lwb-fcc-staging images/sterling/$(LWB_FCC_NAME).tar.bz2

lwb-etsi: lwb-etsi-staging images/sterling/$(LWB_ETSI_NAME).tar.bz2

lwb-mfg: lwb-mfg-staging images/sterling/$(LWB_MFG_NAME).tar.bz2 images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip

lwb5-fcc: lwb5-fcc-staging images/sterling/$(LWB5_FCC_NAME).tar.bz2 images/sterling/480-0081-$(LAIRD_RELEASE_STRING).zip

60: 60-staging images/sterling/$(60_NAME).tar.bz2

wl: images/sterling/$(WL_FMAC_930_0081_NAME).zip

.PHONY: all lwb-fcc lwb-etsi lwb-mfg lwb5-fcc 60 wl clean clean-all clean-nuke
