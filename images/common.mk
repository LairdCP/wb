TOPDIR ?= ../../..

IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images
LEGAL_INFOS = $(TOPDIR)/buildroot/output/$(PRODUCT)/legal-info
BR2_DL_DIR ?= $(TOPDIR)/archive

export DATE ?= $(shell date "+%Y%m%d")

FEATURES = copyall
FILES =

ifeq ($(BULID_TYPE), legacy)

FILES += at91bs.bin u-boot.bin kernel.bin rootfs.bin rootfs.tar.bz2 \
	userfs.bin sqroot.bin \
	fw_update fw_select fw_usi fw.txt prep_nand_for_update

FEATURES += legal-info

else ifeq ($(BULID_TYPE), sd60)

FILES += u-boot-spl.bin u-boot.itb kernel.itb rootfs.tar \
	mksdcard.sh mksdimg.sh

FEATURES += sdk legal-info

else ifeq ($(BULID_TYPE), nand60)

FILES += boot.bin u-boot.itb kernel.itb rootfs.bin $(PRODUCT).swu

FEATURES += sdk legal-info

else ifeq ($(BULID_TYPE), nand60-secure)

FILES += boot.bin u-boot.itb kernel.itb rootfs.bin $(PRODUCT).swu \
	pmecc.bin u-boot-spl.dtb u-boot-spl-nodtb.bin u-boot.dtb \
	u-boot-nodtb.bin u-boot.its kernel-nosig.itb sw-description \
	$(PRODUCT)-full.swu sw-description-full \
	fdtget fdtput mkimage genimage rodata.tar.bz2 rodata-encrypt

FEATURES += sdk legal-info

else ifeq ($(BULID_TYPE), pkg)

FILES += *.tar.* *.zip *.sh *.sha
FILES_EXCLUDE += rootfs.%

endif

# SBOM and CVE-CHECKER files
SBOM_FILES = host-sbom target-sbom
CVE_FILES =  host-cve.xml target-cve.xml

FILES += $(SBOM_FILES) $(CVE_FILES) $(EXTRA_FILES)

FILES_EXIST = $(filter-out $(FILES_EXCLUDE),$(notdir $(wildcard $(addprefix $(IMAGES)/,$(FILES)))))

all: module

copyall:
ifneq ($(FILES_EXIST),)
	cp -t . $(addprefix $(IMAGES)/,$(FILES_EXIST));
	$(foreach FILE,$(filter $(SBOM_FILES),$(FILES_EXIST)), mv -f $(FILE) $(PRODUCT)-$(FILE)-$(DATE);)
	$(foreach FILE,$(filter $(CVE_FILES),$(FILES_EXIST)), mv -f $(FILE) $(patsubst %.xml,%-$(DATE).xml,$(FILE));)
endif

sdk:
	$(MAKE) -C $(TOPDIR)/buildroot/output/$(PRODUCT) sdk
	tar -cjf $(PRODUCT)-sdk.tar.bz2 -C $(TOPDIR)/buildroot/output/$(PRODUCT)/host .

legal-info:
	tar --exclude=*sources -C $(LEGAL_INFOS)/ -cjf legal-info-$(DATE).tar.bz2 .

module:
	mkdir -p "$(DATE)"
	$(MAKE) -f ../../common.mk -C "$(DATE)" $(FEATURES)
	rm -f latest
	ln -rsf "$(DATE)" latest
ifeq ($(BULID_TYPE), legacy)
	ln -rsf "$(DATE)/fw.txt" fw.txt
endif

.PHONY: all copyall sdk legal-info module
