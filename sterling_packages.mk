# Creates a package of required firmware and board support files for the
# Sterling series radios.

ST_OUT := $(PWD)/buildroot/output/sterling

LAIRD_RELEASE_STRING ?= $(shell date +%Y%m%d)

LWB_MFG_NAME := laird-lwb-firmware-mfg-$(LAIRD_RELEASE_STRING)
LWB5_MFG_NAME := laird-lwb5-firmware-mfg-$(LAIRD_RELEASE_STRING)

60_NAME := laird-sterling-60-$(LAIRD_RELEASE_STRING)
WL_FMAC_930_0081_NAME := 930-0081-$(LAIRD_RELEASE_STRING)

LWB_MFG_OUT := $(ST_OUT)/$(LWB_MFG_NAME)
LWB5_MFG_OUT := $(ST_OUT)/$(LWB5_MFG_NAME)

60_OUT := $(ST_OUT)/$(60_NAME)

ST_BRCM_DIR := $(PWD)/buildroot/package/lrd-closed-source/externals/firmware/brcm
ST_LRDMWL_DIR := $(PWD)/buildroot/package/lrd-closed-source/externals/firmware/lrdmwl

ST_IMAGE_DIR := images/sterling

TAR_CJF := tar --owner=root --group=root -cjf

all: lwb-mfg lwb5-mfg 60 wl \
	$(ST_IMAGE_DIR)/480-0079-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0080-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0116-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0081-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0082-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0094-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0095-$(LAIRD_RELEASE_STRING).zip


#############################################################################
# LWB/LWB5 production firmware packages

MAKE_LWB_FAM_PROD_FW_PKG := $(MAKE) -f lwb-family-prod-fw-pkg.mk FW_REPO_DIR=$(PWD)/buildroot/package/lrd-closed-source/externals/firmware

480_0079_PARAMS := FW_PKG_LSR_PN=480-0079 BRCMFMAC_CHIP_ID=43430 CHIP_NAME=4343w REGION=fcc  BUILD_DIR=$(ST_OUT)/480-0079 OUT_FILE=$(ST_IMAGE_DIR)/480-0079-$(LAIRD_RELEASE_STRING).zip
480_0080_PARAMS := FW_PKG_LSR_PN=480-0080 BRCMFMAC_CHIP_ID=43430 CHIP_NAME=4343w REGION=etsi BUILD_DIR=$(ST_OUT)/480-0080 OUT_FILE=$(ST_IMAGE_DIR)/480-0080-$(LAIRD_RELEASE_STRING).zip
480_0116_PARAMS := FW_PKG_LSR_PN=480-0116 BRCMFMAC_CHIP_ID=43430 CHIP_NAME=4343w REGION=jp   BUILD_DIR=$(ST_OUT)/480-0116 OUT_FILE=$(ST_IMAGE_DIR)/480-0116-$(LAIRD_RELEASE_STRING).zip
480_0081_PARAMS := FW_PKG_LSR_PN=480-0081 BRCMFMAC_CHIP_ID=4339  CHIP_NAME=4339  REGION=fcc  BUILD_DIR=$(ST_OUT)/480-0081 OUT_FILE=$(ST_IMAGE_DIR)/480-0081-$(LAIRD_RELEASE_STRING).zip
480_0082_PARAMS := FW_PKG_LSR_PN=480-0082 BRCMFMAC_CHIP_ID=4339  CHIP_NAME=4339  REGION=etsi BUILD_DIR=$(ST_OUT)/480-0082 OUT_FILE=$(ST_IMAGE_DIR)/480-0082-$(LAIRD_RELEASE_STRING).zip
480_0094_PARAMS := FW_PKG_LSR_PN=480-0094 BRCMFMAC_CHIP_ID=4339  CHIP_NAME=4339  REGION=ic   BUILD_DIR=$(ST_OUT)/480-0094 OUT_FILE=$(ST_IMAGE_DIR)/480-0094-$(LAIRD_RELEASE_STRING).zip
480_0095_PARAMS := FW_PKG_LSR_PN=480-0095 BRCMFMAC_CHIP_ID=4339  CHIP_NAME=4339  REGION=jp   BUILD_DIR=$(ST_OUT)/480-0095 OUT_FILE=$(ST_IMAGE_DIR)/480-0095-$(LAIRD_RELEASE_STRING).zip

$(ST_IMAGE_DIR)/480-0079-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0079_PARAMS)

$(ST_IMAGE_DIR)/480-0080-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0080_PARAMS)

$(ST_IMAGE_DIR)/480-0116-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0116_PARAMS)

$(ST_IMAGE_DIR)/480-0081-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0081_PARAMS)

$(ST_IMAGE_DIR)/480-0082-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0082_PARAMS)

$(ST_IMAGE_DIR)/480-0094-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0094_PARAMS)

$(ST_IMAGE_DIR)/480-0095-$(LAIRD_RELEASE_STRING).zip:
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0095_PARAMS)

#############################################################################
# Support targets
$(ST_OUT):
	mkdir -p $(ST_OUT)

#############################################################################
# Image export
$(ST_IMAGE_DIR):
	mkdir -p $(ST_IMAGE_DIR)

# $(@F) is the file part of the target
images/sterling/$(LWB_MFG_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(ST_OUT)/$(LWB_MFG_NAME) ; $(TAR_CJF) ../$(@F) lib
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip: images/sterling/$(LWB_MFG_NAME).tar.bz2
	cd $(ST_OUT) ; zip $(@F) $(LWB_MFG_NAME).tar.bz2
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(LWB5_MFG_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(LWB5_MFG_OUT) ; $(TAR_CJF) $(ST_OUT)/$(@F) lib
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/480-0109-$(LAIRD_RELEASE_STRING).zip: images/sterling/$(LWB5_MFG_NAME).tar.bz2
	cd $(ST_OUT) ; zip $(@F) $(LWB5_MFG_NAME).tar.bz2
	cp $(ST_OUT)/$(@F) $@

# $(@F) is the file part of the target
images/sterling/$(60_NAME).tar.bz2: $(filter-out $(wildcard $(ST_IMAGE_DIR)), $(ST_IMAGE_DIR))
	cd $(60_OUT) ; $(TAR_CJF) $(ST_OUT)/$(@F) lib
	cp $(ST_OUT)/$(@F) $@

images/sterling/$(WL_FMAC_930_0081_NAME).zip: $(ST_OUT)/$(WL_FMAC_930_0081_NAME).zip | $(ST_IMAGE_DIR)
	cp -f $^ $@

lwb-mfg-staging: $(ST_OUT)
	mkdir -p $(LWB_MFG_OUT)/lib/firmware/brcm/bcm4343w
	cd $(LWB_MFG_OUT)/lib/firmware/brcm/bcm4343w ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-*.bin . ; \
	ln -s brcmfmac43430-sdio-mfg.bin brcmfmac43430-sdio.bin ; \
	cp $(ST_BRCM_DIR)/bcm4343w/brcmfmac43430-sdio-*.txt . ; \
	ln -s brcmfmac43430-sdio-fcc.txt brcmfmac43430-sdio.txt ; \
	cp $(ST_BRCM_DIR)/bcm4343w/4343w.hcd .
	cd $(LWB_MFG_OUT)/lib/firmware/brcm ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.bin . ; \
	ln -sf ./bcm4343w/brcmfmac43430-sdio.txt . ; \
	ln -sf ./bcm4343w/4343w.hcd .

lwb5-mfg-staging: $(ST_OUT)
	mkdir -p $(LWB5_MFG_OUT)/lib/firmware/brcm/bcm4339
	cd $(LWB5_MFG_OUT)/lib/firmware/brcm/bcm4339 ; \
	cp $(ST_BRCM_DIR)/bcm4339/brcmfmac4339-sdio-*.bin . ; \
	ln -s brcmfmac4339-sdio-mfg.bin brcmfmac4339-sdio.bin ; \
	cp $(ST_BRCM_DIR)/bcm4339/brcmfmac4339-sdio-*.txt . ; \
	ln -s brcmfmac4339-sdio-fcc.txt brcmfmac4339-sdio.txt ; \
	cp $(ST_BRCM_DIR)/bcm4339/4339.hcd . ; \
	cd $(LWB5_MFG_OUT)/lib/firmware/brcm ; \
	ln -sf ./bcm4339/brcmfmac4339-sdio.bin . ; \
	ln -sf ./bcm4339/brcmfmac4339-sdio.txt . ; \
	ln -sf ./bcm4339/4339.hcd .

60-staging: $(ST_OUT)
	mkdir -p $(60_OUT)/lib/firmware/
	cp -rd $(ST_LRDMWL_DIR) $(60_OUT)/lib/firmware/

$(ST_OUT)/$(WL_FMAC_930_0081_NAME).zip: buildroot/package/lrd-closed-source/externals/wl_fmac/bin/930-0081/wl_fmac | $(ST_OUT)
	zip --junk-paths $@ $^


#############################################################################
#  clean targets
clean-all:
	rm -rf $(ST_OUT)
	rm -f images/sterling/$(LWB5_MFG_NAME).tar.bz2
	rm -f images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/480-0109-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/$(60_NAME).tar.bz2

clean:
	rm -rf $(LWB_MFG_OUT)
	rm -rf $(LWB5_MFG_OUT)
	rm -rf $(60_OUT)
	rm -f $(ST_OUT)/$(LWB_MFG_NAME).tar.bz2
	rm -f $(ST_OUT)/$(LWB5_MFG_NAME).tar.bz2
	rm -f $(ST_OUT)/480-0108-$(LAIRD_RELEASE_STRING).zip
	rm -f $(ST_OUT)/480-0109-$(LAIRD_RELEASE_STRING).zip
	rm -f $(ST_OUT)/$(WL_FMAC_930_0081_NAME).zip
	rm -f images/sterling/$(LWB_MFG_NAME).tar.bz2
	rm -f images/sterling/$(LWB5_MFG_NAME).tar.bz2
	rm -f images/sterling/$(WL_FMAC_930_0081_NAME).zip
	rm -f images/sterling/$(60_NAME).tar.bz2
	rm -f images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip
	rm -f images/sterling/480-0109-$(LAIRD_RELEASE_STRING).zip
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0079_PARAMS) clean
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0080_PARAMS) clean
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0116_PARAMS) clean
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0081_PARAMS) clean
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0082_PARAMS) clean
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0094_PARAMS) clean
	$(MAKE_LWB_FAM_PROD_FW_PKG) $(480_0095_PARAMS) clean

clean-nuke:
	rm -rf $(ST_OUT)
	rm -rf images/sterling

#############################################################################
# top level targets

lwb-mfg: lwb-mfg-staging images/sterling/$(LWB_MFG_NAME).tar.bz2 images/sterling/480-0108-$(LAIRD_RELEASE_STRING).zip

lwb5-mfg: lwb5-mfg-staging images/sterling/$(LWB5_MFG_NAME).tar.bz2 images/sterling/480-0109-$(LAIRD_RELEASE_STRING).zip

60: 60-staging images/sterling/$(60_NAME).tar.bz2

wl: images/sterling/$(WL_FMAC_930_0081_NAME).zip

.PHONY: all lwb-mfg lwb5-mfg 60 wl clean clean-all clean-nuke \
	$(ST_IMAGE_DIR)/480-0079-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0080-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0116-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0081-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0082-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0094-$(LAIRD_RELEASE_STRING).zip \
	$(ST_IMAGE_DIR)/480-0095-$(LAIRD_RELEASE_STRING).zip
