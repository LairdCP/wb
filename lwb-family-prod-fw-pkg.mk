#
# This makefile uses a lot of automatic variables. For help, refer to
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
#

FW_PKG_LSR_PN ?= 000-0000
BRCMFMAC_CHIP_ID ?= 00000
CHIP_NAME ?= 0000
REGION ?= xyz

FW_REPO_DIR ?= ./buildroot/package/lrd-closed-source/externals/firmware
OUT_FILE ?= $(PWD)/$(FW_PKG_LSR_PN).zip
BUILD_DIR ?= $(dir $(OUT_FILE))/build-$(FW_PKG_LSR_PN)

###############################################################################

OUT_DIR := $(dir $(OUT_FILE))
ARCHIVE_ROOT := $(BUILD_DIR)/archive
HINT_FILE := $(OUT_FILE)-$(CHIP_NAME)-$(REGION).hint

ZIP := zip
TAR_F := tar --owner=root --group=root -cjf
CP_F := cp -f

$(OUT_FILE): $(BUILD_DIR)/$(FW_PKG_LSR_PN).zip | $(OUT_DIR) $(HINT_FILE)
	cp -f $< $@

$(HINT_FILE): $(OUT_DIR)
	touch $@

$(OUT_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(FW_PKG_LSR_PN).zip: $(BUILD_DIR)/$(FW_PKG_LSR_PN).tar.bz2
	cd $(BUILD_DIR); $(ZIP) $@ $(FW_PKG_LSR_PN).tar.bz2

$(BUILD_DIR)/$(FW_PKG_LSR_PN).tar.bz2: $(ARCHIVE_ROOT)/lib/firmware/brcm/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.bin $(ARCHIVE_ROOT)/lib/firmware/brcm/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.txt $(ARCHIVE_ROOT)/lib/firmware/brcm/$(CHIP_NAME).hcd | $(OUT_DIR)
	cd $(ARCHIVE_ROOT); $(TAR_F) $@ lib

#
# $(ARCHIVE_ROOT)/lib/firmware/brcm
#

$(ARCHIVE_ROOT)/lib/firmware/brcm/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.bin: $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.bin
	cd $(@D); ln -sf ./bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.bin $(@F)

$(ARCHIVE_ROOT)/lib/firmware/brcm/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.txt: $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.txt
	cd $(@D); ln -sf ./bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.txt $(@F)

$(ARCHIVE_ROOT)/lib/firmware/brcm/$(CHIP_NAME).hcd: $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/$(CHIP_NAME).hcd
	cd $(@D); ln -sf ./bcm$(CHIP_NAME)/$(CHIP_NAME).hcd $(@F)

#
# $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)
#

$(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.bin: $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-prod.bin
	cd $(@D); ln -sf ./brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-prod.bin $(@F)

$(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio.txt: $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-$(REGION).txt
	cd $(@D); ln -sf ./brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-$(REGION).txt $(@F)

$(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-prod.bin: $(FW_REPO_DIR)/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-prod.bin | $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)
	$(CP_F) $(FW_REPO_DIR)/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-prod.bin $@

$(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-$(REGION).txt: $(FW_REPO_DIR)/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-$(REGION).txt | $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)
	$(CP_F) $(FW_REPO_DIR)/brcm/bcm$(CHIP_NAME)/brcmfmac$(BRCMFMAC_CHIP_ID)-sdio-$(REGION).txt $@

$(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)/$(CHIP_NAME).hcd: $(FW_REPO_DIR)/brcm/bcm$(CHIP_NAME)/$(CHIP_NAME).hcd | $(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME)
	$(CP_F) $(FW_REPO_DIR)/brcm/bcm$(CHIP_NAME)/$(CHIP_NAME).hcd $@

$(ARCHIVE_ROOT)/lib/firmware/brcm/bcm$(CHIP_NAME):
	mkdir -p $@

#
# Miscellaneous
#

clean:
	rm -f $(OUT_FILE)
	rm -f $(HINT_FILE)
	rm -rf $(BUILD_DIR)

.PHONY: clean
