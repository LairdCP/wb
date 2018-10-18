# Coccinelle requires:
# sudo apt-get install coccinelle
#
# Backports addtionally requires:
# sudo apt-get install libncurses5-dev
#    Note that libncurses5-dev is required by the WB build, so you probably already have it

BP_OUT := $(PWD)/buildroot/output/backport

SPATCH_PATH := /usr/local/bin/spatch

PATH := $(PATH):$(BP_OUT)/staging/bin
LAIRD_RELEASE_STRING ?= $(shell date +%Y%m%d)

BP_TREE :=  $(BP_OUT)/laird-backport-tree
BP_TREE_WORKING :=  $(BP_OUT)/laird-backport-tree-working
BP_LINUX_DIR :=  $(PWD)/buildroot/package/lrd/externals/kernel
BP_LINUX_BUILT:= $(PWD)/buildroot/output/wb50n/build/linux-4.1.13
BP_TEST_TARGET:= $(PWD)/buildroot/output/wb50n/target
BP_TEST_TREE := $(BP_OUT)/modules

BP_IMAGE_DIR := images/backport

all: backport image

#############################################################################
# Support targets
$(BP_OUT):
	mkdir -p $(BP_OUT)/staging

#############################################################################
# Backports components
backports:
	$(error backports clone was not found, please retrieve via `repo sync`)

$(BP_TREE): backports $(filter-out $(wildcard $(BP_OUT)), $(BP_OUT))
	./backports/gentree.py --clean --copy-list ./backports/copy-list \
			       $(BP_LINUX_DIR) \
			       $(BP_TREE_WORKING)
	mv $(BP_TREE_WORKING) $(BP_TREE) # necessary to catch failure of prev step

#############################################################################
# Image export
$(BP_IMAGE_DIR):
	mkdir -p $(BP_IMAGE_DIR)

# $(@F) is the file part of the target
# $(<F) is the file part of the first prerequesite
images/backport/laird-backport-$(LAIRD_RELEASE_STRING).tar.bz2: $(BP_TREE) $(filter-out $(wildcard $(BP_IMAGE_DIR)), $(BP_IMAGE_DIR))
	cd $(<) ; tar -cj --transform "s,^,laird-backport-$(LAIRD_RELEASE_STRING)/," -f ../$(@F) .
	cp $(BP_OUT)/$(@F) $@

#############################################################################
# Test targets

CROSS_COMPILE := arm-laird-linux-gnueabi-
ARCH := arm
KLIB_BUILD := $(BP_LINUX_BUILT)
KLIB := $(BP_TEST_TREE)

export KLIB KLIB_BUILD ARCH CROSS_COMPILE

wb50-test: $(BP_TREE)
	mkdir -p $(BP_TEST_TREE)
	cd $(BP_TREE) ; \
		make defconfig-laird
	cd $(BP_TREE) ; \
		make
	cd $(BP_TREE)/compat ; \
		cp compat.ko $(BP_TEST_TREE)/
	cd $(BP_TREE)/net/wireless ; \
		cp cfg80211.ko $(BP_TEST_TREE)/
	cd $(BP_TREE)/drivers/net/wireless/laird_fips ; \
		cp ath6kl_laird.ko sdc2u.ko $(BP_TEST_TREE)/
	cd $(BP_TREE)/drivers/net/wireless/ath/ath6kl ; \
		cp ath6kl_core.ko ath6kl_sdio.ko ath6kl_usb.ko $(BP_TEST_TREE)/
	cd $(BP_TREE)/drivers/net/wireless/brcm80211 ; \
		cp brcmfmac/brcmfmac.ko brcmutil/brcmutil.ko $(BP_TEST_TREE)/

#############################################################################
#  clean targets
clean-all:
	rm -rf $(BP_OUT)
	rm -rf $(BP_TEST_TREE)
	rm -f images/backport/backport-$(LAIRD_RELEASE_STRING).tar.bz2

clean:
	rm -rf $(BP_TREE)
	rm -rf $(BP_TEST_TREE)
	rm -f images/backport/backport-$(LAIRD_RELEASE_STRING).tar.bz2

clean-nuke:
	rm -rf $(BP_OUT)
	rm -rf $(BP_TEST_TREE)
	rm -rf images/backport

#############################################################################
# top level targets
backport: $(BP_TREE)

image: images/backport/laird-backport-$(LAIRD_RELEASE_STRING).tar.bz2

.PHONY: all image backport wb50-test clean clean-all clean-nuke
