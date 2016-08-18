# Coccinelle requires:
# sudo apt-get install ocaml ocaml-findlib libpycaml-ocaml-dev
# sudo apt-get install menhir libmenhir-ocaml-dev
# sudo apt-get install libpcre-ocaml-dev
#
# Backports addtionally requires:
# sudo apt-get install libncurses-dev
#    Note that libncurses-dev is required by the WB build, so you probably already have it

BP_OUT := $(PWD)/buildroot/output/backport
BP_COCCINELLE_URL = https://github.com/coccinelle/coccinelle.git

SPATCH_PATH := /usr/local/bin/spatch

PATH := $(PATH):$(BP_OUT)/staging/bin
LAIRD_RELEASE_STRING ?= $(shell date +%Y%m%d)

BP_TREE :=  $(BP_OUT)/laird-backport-tree
BP_TREE_WORKING :=  $(BP_OUT)/laird-backport-tree-working
BP_SPATCH := $(BP_OUT)/staging/bin/spatch
BP_LINUX_DIR :=  $(PWD)/buildroot/package/lrd-closed-source/externals/kernel
BP_LINUX_BUILT:= $(PWD)/buildroot/output/wb50n/build/linux-4.1.13
BP_TEST_TARGET:= $(PWD)/buildroot/output/wb50n/target
BP_TEST_TREE := $(BP_OUT)/modules

BP_IMAGE_DIR := images/backport

all: backport image

#############################################################################
# Support targets
$(BP_OUT):
	mkdir -p $(BP_OUT)/staging

$(BP_SPATCH): $(BP_OUT)/coccinelle
	cd $(BP_OUT)/coccinelle ; ./configure --prefix=$(BP_OUT)/staging
	cd $(BP_OUT)/coccinelle ; make
	cd $(BP_OUT)/coccinelle ; make install

$(BP_OUT)/coccinelle: $(filter-out $(wildcard $(BP_OUT)), $(BP_OUT))
	git clone --depth 1 -b ubuntu/15.04-vivid/1.0.2 $(BP_COCCINELLE_URL) $(BP_OUT)/coccinelle

#############################################################################
# Backports components
backports:
	$(error backports clone was not found, please retrieve via `repo sync`)

ifeq ("$(wildcard $(SPATCH_PATH))","")
SPATCH_PRE=$(BP_SPATCH)
endif

$(BP_TREE): $(SPATCH_PRE) backports $(filter-out $(wildcard $(BP_OUT)), $(BP_OUT))
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
