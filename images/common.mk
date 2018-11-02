
# PRODUCT must be set to wb40n or wb45n

URL = http://$(shell hostname)/wb/$(PRODUCT)

TOPDIR = ../../..
IMAGES = $(TOPDIR)/buildroot/output/$(PRODUCT)/images

# SBOM and CVE-CHECKER files
SBOM_FILES = host-sbom target-sbom
CVE_FILES =  host-cve.xml target-cve.xml

cve:
	$(foreach FILE,$(CVE_FILES), $(shell [ -e $(IMAGES)/$(FILE) ] && cp $(IMAGES)/$(FILE) $(subst .xml,"-$(DATE).xml", $(PRODUCT)-$(FILE))))

sbom:
	$(foreach FILE,$(SBOM_FILES), $(shell [ -e $(IMAGES)/$(FILE) ] && cp $(IMAGES)/$(FILE) $(PRODUCT)-$(FILE)-$(DATE)))

legal-info:
	rsync -a --exclude=sources $(TOPDIR)/buildroot/output/$(PRODUCT)/legal-info/ ./legal-info-$(DATE)
	tar cjf legal-info-$(DATE).tar.bz ./legal-info-$(DATE)
	rm -f latest.tar.bz
	ln -s legal-info-$(DATE).tar.bz latest.tar.bz
	rm -rf ./legal-info-$(DATE)

copyall:
	cp $(IMAGES)/at91bs.bin .
	cp $(IMAGES)/u-boot.bin .
	cp $(IMAGES)/kernel.bin .
	cp $(IMAGES)/rootfs.bin .
	cp $(IMAGES)/fw_update .
	cp $(IMAGES)/fw_select .
	cp $(IMAGES)/fw_usi .
	cp $(IMAGES)/fw.txt .
	cp $(IMAGES)/rootfs.tar .
	rm -f rootfs.tar.bz2
	bzip2 rootfs.tar

all: copyall

.PHONY: all copyall legal-info
